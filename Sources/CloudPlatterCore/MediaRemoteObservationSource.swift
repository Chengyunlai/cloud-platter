import Foundation

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
    private let initialOutputTimeout: Duration
    private let recoveryCooldown: Duration
    private let maximumRecoveryCycles: Int?

    public init() {
        let paths = MediaRemoteAdapterPaths.bundled()
        self.init(
            paths: paths,
            executor: FoundationMediaRemoteProcessExecutor(executable: paths.supervisor),
            restartDelays: [.seconds(1), .seconds(2), .seconds(4)],
            initialOutputTimeout: .seconds(10),
            recoveryCooldown: .seconds(30),
            maximumRecoveryCycles: nil
        )
    }

    init(
        paths: MediaRemoteAdapterPaths,
        executor: any MediaRemoteProcessExecuting,
        restartDelays: [Duration],
        initialOutputTimeout: Duration = .seconds(10),
        recoveryCooldown: Duration = .zero,
        maximumRecoveryCycles: Int? = 1
    ) {
        self.paths = paths
        self.executor = executor
        self.restartDelays = restartDelays
        self.initialOutputTimeout = initialOutputTimeout
        self.recoveryCooldown = recoveryCooldown
        self.maximumRecoveryCycles = maximumRecoveryCycles
    }

    /// 验证资源完整性及 Apple Perl 宿主当前是否仍具备 MediaRemote 能力。
    public func checkCapability() async -> MediaRemoteAdapterCapability {
        if let reason = validateResources() {
            return .unavailable(reason)
        }

        let result = await executor.run(
            arguments: adapterArguments(command: .test),
            timeout: .seconds(15)
        )

        switch result {
        case .success(0):
            return .available
        case .success(let exitCode):
            return .unavailable(.capabilityTestFailed(exitCode: exitCode))
        case .failure(.timedOut):
            return .unavailable(.capabilityTestTimedOut)
        case .failure(.launchFailed), .failure(.terminated), .failure(.invalidOutput):
            return .unavailable(.launchFailed)
        }
    }

    /// 返回实时状态序列；能力缺失或连续重启失败时以 `.unavailable` 安全结束。
    public func states() -> AsyncStream<NowPlayingState> {
        AsyncStream { continuation in
            let task = Task {
                var completedRecoveryCycles = 0

                while !Task.isCancelled {
                    if await checkCapability() == .available {
                        await runStreamAttemptCycle(continuation: continuation)
                    }

                    guard !Task.isCancelled else {
                        break
                    }

                    continuation.yield(NowPlayingState(status: .unavailable))
                    completedRecoveryCycles += 1

                    if let maximumRecoveryCycles,
                        completedRecoveryCycles >= maximumRecoveryCycles
                    {
                        break
                    }

                    do {
                        try await Task.sleep(for: recoveryCooldown)
                    } catch {
                        break
                    }
                }

                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    private func runStreamAttemptCycle(
        continuation: AsyncStream<NowPlayingState>.Continuation
    ) async {
        let attemptDelays = [Duration.zero] + restartDelays
        for delay in attemptDelays {
            guard !Task.isCancelled else {
                return
            }

            if delay != .zero {
                do {
                    try await Task.sleep(for: delay)
                } catch {
                    return
                }
            }

            var decoder = MediaRemoteStreamDecoder()
            do {
                for try await line in executor.lines(
                    arguments: adapterArguments(
                        command: .stream, options: ["--debounce=100"]),
                    initialOutputTimeout: initialOutputTimeout
                ) {
                    guard !Task.isCancelled else {
                        return
                    }

                    do {
                        continuation.yield(try decoder.decode(line: line))
                    } catch {
                        // 坏事件之后不能继续合并旧快照，必须重启并等待新的全量事件。
                        throw MediaRemoteProcessError.invalidOutput
                    }
                }
            } catch {
                // 子进程异常只触发有上限的短重试，不把 stderr 或原始内容写入日志。
            }

            await Task.yield()
        }
    }

    private func validateResources() -> MediaRemoteAdapterUnavailableReason? {
        let fileManager = FileManager.default
        guard fileManager.isExecutableFile(atPath: paths.perlExecutable.path) else {
            return .missingPerl
        }

        let requiredResources = [
            paths.supervisor,
            paths.script,
            paths.framework,
            paths.testClient,
        ]
        for resource in requiredResources where !fileManager.fileExists(atPath: resource.path) {
            return .missingResource(resource.lastPathComponent)
        }

        let requiredExecutables = [paths.supervisor, paths.testClient]
        for executable in requiredExecutables
        where !fileManager.isExecutableFile(atPath: executable.path) {
            return .missingResource(executable.lastPathComponent)
        }

        return nil
    }

    private func adapterArguments(command: AdapterCommand, options: [String] = []) -> [String] {
        [
            paths.perlExecutable.path,
            paths.script.path,
            paths.framework.path,
            paths.testClient.path,
            command.rawValue,
        ] + options
    }
}

private enum AdapterCommand: String {
    case test
    case stream
}
