import Foundation

enum MediaRemoteProcessError: Error, Equatable, Sendable {
    case launchFailed
    case timedOut
    case terminated(exitCode: Int32)
    case invalidOutput
}

protocol MediaRemoteProcessExecuting: Sendable {
    func run(arguments: [String], timeout: Duration) async
        -> Result<Int32, MediaRemoteProcessError>
    func lines(arguments: [String], initialOutputTimeout: Duration)
        -> AsyncThrowingStream<Data, any Error>
}

final class FoundationMediaRemoteProcessExecutor: MediaRemoteProcessExecuting,
    @unchecked Sendable
{
    private let executable: URL

    init(executable: URL) {
        self.executable = executable
    }

    func run(arguments: [String], timeout: Duration) async
        -> Result<Int32, MediaRemoteProcessError>
    {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        let processBox = RunningProcessBox(process: process)

        return await withCheckedContinuation { continuation in
            let completion = ProcessCompletion(continuation: continuation)
            process.terminationHandler = { terminatedProcess in
                completion.finish(.success(terminatedProcess.terminationStatus))
            }

            do {
                try process.run()
            } catch {
                completion.finish(.failure(.launchFailed))
                return
            }

            Task {
                do {
                    try await Task.sleep(for: timeout)
                } catch {
                    return
                }

                if completion.finish(.failure(.timedOut)) {
                    processBox.terminate()
                }
            }
        }
    }

    func lines(arguments: [String], initialOutputTimeout: Duration)
        -> AsyncThrowingStream<Data, any Error>
    {
        AsyncThrowingStream { continuation in
            let process = Process()
            let outputPipe = Pipe()
            process.executableURL = executable
            process.arguments = arguments
            process.standardOutput = outputPipe
            process.standardError = FileHandle.nullDevice

            let processBox = RunningProcessBox(process: process, outputPipe: outputPipe)
            let emitter = LineEmitter(continuation: continuation)

            do {
                try process.run()
            } catch {
                continuation.finish(throwing: MediaRemoteProcessError.launchFailed)
                return
            }

            let timeoutTask = Task.detached {
                do {
                    try await Task.sleep(for: initialOutputTimeout)
                } catch {
                    return
                }

                if emitter.failIfNoLine() {
                    processBox.terminate()
                }
            }

            let readerTask = Task.detached {
                while !Task.isCancelled {
                    let data = processBox.readAvailableData()
                    guard !data.isEmpty else {
                        break
                    }
                    emitter.receive(data)
                }

                processBox.waitUntilExit()
                timeoutTask.cancel()
                emitter.finish(exitCode: processBox.terminationStatus)
            }

            continuation.onTermination = { _ in
                timeoutTask.cancel()
                readerTask.cancel()
                processBox.terminate()
            }
        }
    }
}

private final class RunningProcessBox: @unchecked Sendable {
    private let process: Process
    private let outputPipe: Pipe?

    init(process: Process, outputPipe: Pipe? = nil) {
        self.process = process
        self.outputPipe = outputPipe
    }

    var terminationStatus: Int32 {
        process.terminationStatus
    }

    func readAvailableData() -> Data {
        outputPipe?.fileHandleForReading.availableData ?? Data()
    }

    func waitUntilExit() {
        process.waitUntilExit()
    }

    func terminate() {
        guard process.isRunning else {
            return
        }
        process.terminate()
    }
}

private final class ProcessCompletion: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Result<Int32, MediaRemoteProcessError>, Never>?

    init(continuation: CheckedContinuation<Result<Int32, MediaRemoteProcessError>, Never>) {
        self.continuation = continuation
    }

    @discardableResult
    func finish(_ result: Result<Int32, MediaRemoteProcessError>) -> Bool {
        lock.lock()
        guard let continuation else {
            lock.unlock()
            return false
        }
        self.continuation = nil
        lock.unlock()

        continuation.resume(returning: result)
        return true
    }
}

private final class LineEmitter: @unchecked Sendable {
    private let lock = NSLock()
    private var buffer = Data()
    private var hasEmittedLine = false
    private var continuation: AsyncThrowingStream<Data, any Error>.Continuation?

    init(continuation: AsyncThrowingStream<Data, any Error>.Continuation) {
        self.continuation = continuation
    }

    func receive(_ data: Data) {
        lock.lock()
        guard let continuation else {
            lock.unlock()
            return
        }

        buffer.append(data)
        var lines: [Data] = []
        while let newlineIndex = buffer.firstIndex(of: 0x0A) {
            var line = Data(buffer[..<newlineIndex])
            buffer.removeSubrange(...newlineIndex)
            if line.last == 0x0D {
                line.removeLast()
            }
            if !line.isEmpty {
                hasEmittedLine = true
                lines.append(line)
            }
        }
        lock.unlock()

        for line in lines {
            continuation.yield(line)
        }
    }

    func failIfNoLine() -> Bool {
        lock.lock()
        guard !hasEmittedLine, let continuation else {
            lock.unlock()
            return false
        }
        self.continuation = nil
        lock.unlock()

        continuation.finish(throwing: MediaRemoteProcessError.timedOut)
        return true
    }

    func finish(exitCode: Int32) {
        lock.lock()
        guard let continuation else {
            lock.unlock()
            return
        }

        let trailingLine = buffer.isEmpty ? nil : buffer
        buffer.removeAll(keepingCapacity: false)
        self.continuation = nil
        lock.unlock()

        if let trailingLine {
            continuation.yield(trailingLine)
        }

        if exitCode == 0 {
            continuation.finish()
        } else {
            continuation.finish(
                throwing: MediaRemoteProcessError.terminated(exitCode: exitCode)
            )
        }
    }
}
