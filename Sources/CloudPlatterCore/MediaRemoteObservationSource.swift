import Foundation

/// 定位应用包内 MediaRemote Adapter 所需的全部运行时资源。
public struct MediaRemoteAdapterPaths: Equatable, Sendable {
    public let perlExecutable: URL
    public let script: URL
    public let framework: URL
    public let testClient: URL

    public init(
        perlExecutable: URL,
        script: URL,
        framework: URL,
        testClient: URL
    ) {
        self.perlExecutable = perlExecutable
        self.script = script
        self.framework = framework
        self.testClient = testClient
    }

    /// 按 CloudPlatter 安装包约定生成默认资源路径。
    public static func bundled(in bundle: Bundle = .main) -> Self {
        let resourceRoot =
            bundle.resourceURL ?? bundle.bundleURL.appendingPathComponent("Resources")
        let adapterRoot = resourceRoot.appendingPathComponent("MediaRemoteAdapter")

        return Self(
            perlExecutable: URL(fileURLWithPath: "/usr/bin/perl"),
            script: adapterRoot.appendingPathComponent("mediaremote-adapter.pl"),
            framework: adapterRoot.appendingPathComponent("MediaRemoteAdapter.framework"),
            testClient: adapterRoot.appendingPathComponent("MediaRemoteAdapterTestClient")
        )
    }
}

/// 描述适配器在当前系统不可用的脱敏原因。
public enum MediaRemoteAdapterUnavailableReason: Equatable, Sendable {
    case missingPerl
    case missingResource(String)
    case capabilityTestFailed(exitCode: Int32)
    case capabilityTestTimedOut
    case launchFailed
}

/// 表示适配器是否可以在当前系统安全启动。
public enum MediaRemoteAdapterCapability: Equatable, Sendable {
    case available
    case unavailable(MediaRemoteAdapterUnavailableReason)
}

/// 运行隔离 helper，并以规范化状态序列暴露网易云音乐的实时播放变化。
public struct MediaRemoteObservationSource: Sendable {
    private let paths: MediaRemoteAdapterPaths
    private let executor: any MediaRemoteProcessExecuting
    private let restartDelays: [Duration]

    public init(paths: MediaRemoteAdapterPaths = .bundled()) {
        self.init(
            paths: paths,
            executor: FoundationMediaRemoteProcessExecutor(executable: paths.perlExecutable),
            restartDelays: [.seconds(1), .seconds(2), .seconds(4)]
        )
    }

    init(
        paths: MediaRemoteAdapterPaths,
        executor: any MediaRemoteProcessExecuting,
        restartDelays: [Duration]
    ) {
        self.paths = paths
        self.executor = executor
        self.restartDelays = restartDelays
    }

    /// 验证资源完整性及 Apple Perl 宿主当前是否仍具备 MediaRemote 能力。
    public func checkCapability() async -> MediaRemoteAdapterCapability {
        if let reason = validateResources() {
            return .unavailable(reason)
        }

        let result = await executor.run(
            arguments: adapterArguments(command: "test"),
            timeout: .seconds(15)
        )

        switch result {
        case .success(0):
            return .available
        case .success(let exitCode):
            return .unavailable(.capabilityTestFailed(exitCode: exitCode))
        case .failure(.timedOut):
            return .unavailable(.capabilityTestTimedOut)
        case .failure(.launchFailed), .failure(.terminated):
            return .unavailable(.launchFailed)
        }
    }

    /// 返回实时状态序列；能力缺失或连续重启失败时以 `.unavailable` 安全结束。
    public func states() -> AsyncStream<NowPlayingState> {
        AsyncStream { continuation in
            let task = Task {
                guard await checkCapability() == .available else {
                    continuation.yield(NowPlayingState(status: .unavailable))
                    continuation.finish()
                    return
                }

                let attemptDelays = [Duration.zero] + restartDelays
                for (attempt, delay) in attemptDelays.enumerated() {
                    guard !Task.isCancelled else {
                        break
                    }

                    if delay != .zero {
                        do {
                            try await Task.sleep(for: delay)
                        } catch {
                            break
                        }
                    }

                    var decoder = MediaRemoteStreamDecoder()
                    do {
                        for try await line in executor.lines(
                            arguments: adapterArguments(
                                command: "stream", options: ["--debounce=100"])
                        ) {
                            guard !Task.isCancelled else {
                                break
                            }

                            do {
                                continuation.yield(try decoder.decode(line: line))
                            } catch {
                                continuation.yield(NowPlayingState(status: .unavailable))
                            }
                        }
                    } catch {
                        // 子进程异常与解析失败都只转换为脱敏状态，不把 stderr 或原始内容写入日志。
                    }

                    if attempt == attemptDelays.indices.last {
                        continuation.yield(NowPlayingState(status: .unavailable))
                    }
                }

                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    private func validateResources() -> MediaRemoteAdapterUnavailableReason? {
        let fileManager = FileManager.default
        guard fileManager.isExecutableFile(atPath: paths.perlExecutable.path) else {
            return .missingPerl
        }

        let requiredResources = [paths.script, paths.framework, paths.testClient]
        for resource in requiredResources where !fileManager.fileExists(atPath: resource.path) {
            return .missingResource(resource.lastPathComponent)
        }

        guard fileManager.isExecutableFile(atPath: paths.testClient.path) else {
            return .missingResource(paths.testClient.lastPathComponent)
        }

        return nil
    }

    private func adapterArguments(command: String, options: [String] = []) -> [String] {
        [
            paths.script.path,
            paths.framework.path,
            paths.testClient.path,
            command,
        ] + options
    }
}

enum MediaRemoteProcessError: Error, Equatable, Sendable {
    case launchFailed
    case timedOut
    case terminated(exitCode: Int32)
}

protocol MediaRemoteProcessExecuting: Sendable {
    func run(arguments: [String], timeout: Duration) async
        -> Result<Int32, MediaRemoteProcessError>
    func lines(arguments: [String]) -> AsyncThrowingStream<Data, any Error>
}

private final class FoundationMediaRemoteProcessExecutor: MediaRemoteProcessExecuting,
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

    func lines(arguments: [String]) -> AsyncThrowingStream<Data, any Error> {
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

            let readerTask = Task.detached {
                while !Task.isCancelled {
                    let data = processBox.readAvailableData()
                    guard !data.isEmpty else {
                        break
                    }
                    emitter.receive(data)
                }

                processBox.waitUntilExit()
                emitter.finish(exitCode: processBox.terminationStatus)
            }

            continuation.onTermination = { _ in
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
                lines.append(line)
            }
        }
        lock.unlock()

        for line in lines {
            continuation.yield(line)
        }
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
