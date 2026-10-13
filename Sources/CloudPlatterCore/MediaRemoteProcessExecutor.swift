import Foundation

enum MediaRemoteProcessError: Error, Equatable, Sendable {
    case launchFailed
    case timedOut
    case cancelled
    case terminated(exitCode: Int32)
    case invalidOutput
}

/// 隔离系统进程调用，使能力测试与实时行流共享一致的超时、取消和失败边界。
///
/// 实现不得输出 stderr 或原始媒体内容；一次性调用超时后必须终止进程，实时调用在首行超时、
/// 非零退出或调用方取消时必须结束序列并释放子进程。
protocol MediaRemoteProcessExecuting: Sendable {
    /// 执行一次性命令，并把启动失败、超时和退出码转换为脱敏结果。
    func run(arguments: [String], timeout: Duration) async
        -> Result<Int32, MediaRemoteProcessError>

    /// 启动实时命令并逐行输出 stdout；在指定时间内没有完整首行时抛出超时错误。
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

        let operation = OneShotProcessOperation(process: process)
        return await withTaskCancellationHandler {
            await operation.run(timeout: timeout)
        } onCancel: {
            operation.finish(.failure(.cancelled), terminateProcess: true)
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

/// 启动、取消、超时和退出共用同一把锁，避免取消先到时仍启动进程或重复恢复调用方。
private final class OneShotProcessOperation: @unchecked Sendable {
    private let lock = NSLock()
    private let process: Process
    private var continuation: CheckedContinuation<Result<Int32, MediaRemoteProcessError>, Never>?
    private var result: Result<Int32, MediaRemoteProcessError>?
    private var timeoutTask: Task<Void, Never>?

    init(process: Process) {
        self.process = process
    }

    func run(timeout: Duration) async -> Result<Int32, MediaRemoteProcessError> {
        await withCheckedContinuation { continuation in
            start(continuation: continuation, timeout: timeout)
        }
    }

    private func start(
        continuation: CheckedContinuation<Result<Int32, MediaRemoteProcessError>, Never>,
        timeout: Duration
    ) {
        lock.lock()
        if let result {
            lock.unlock()
            continuation.resume(returning: result)
            return
        }
        self.continuation = continuation
        process.terminationHandler = { [weak self] process in
            self?.finish(.success(process.terminationStatus))
        }
        do {
            try process.run()
        } catch {
            lock.unlock()
            finish(.failure(.launchFailed))
            return
        }
        timeoutTask = Task { [weak self] in
            do {
                try await Task.sleep(for: timeout)
            } catch {
                return
            }
            self?.finish(.failure(.timedOut), terminateProcess: true)
        }
        lock.unlock()
    }

    func finish(
        _ result: Result<Int32, MediaRemoteProcessError>,
        terminateProcess: Bool = false
    ) {
        lock.lock()
        guard self.result == nil else {
            lock.unlock()
            return
        }
        self.result = result
        let continuation = self.continuation
        self.continuation = nil
        let timeoutTask = self.timeoutTask
        self.timeoutTask = nil
        if terminateProcess, process.isRunning {
            process.terminate()
        }
        lock.unlock()

        timeoutTask?.cancel()
        continuation?.resume(returning: result)
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
