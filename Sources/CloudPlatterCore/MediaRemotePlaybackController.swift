import Foundation

/// 通过隔离的 MediaRemote Adapter 向当前网易云音乐发送用户主动播放命令。
public actor MediaRemotePlaybackController: PlaybackControlling {
    private let paths: MediaRemoteAdapterPaths
    private let executor: any MediaRemoteProcessExecuting
    private let requestTimeout: Duration

    public init() {
        let paths = MediaRemoteAdapterPaths.bundled()
        self.init(
            paths: paths,
            executor: FoundationMediaRemoteProcessExecutor(executable: paths.perlExecutable),
            requestTimeout: PlaybackControlTiming.requestTimeout
        )
    }

    init(
        paths: MediaRemoteAdapterPaths,
        executor: any MediaRemoteProcessExecuting,
        requestTimeout: Duration
    ) {
        self.paths = paths
        self.executor = executor
        self.requestTimeout = requestTimeout
    }

    public func send(_ command: PlaybackControlCommand) async -> PlaybackControlResult {
        guard paths.hasRequiredRuntimeResources() else {
            return .failed(.unavailable)
        }
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: requestTimeout)

        switch await currentTargetValidation(deadline: deadline, clock: clock) {
        case .supported:
            break
        case .unsupported:
            return .failed(.unsupportedSource)
        case .unavailable:
            return .failed(.unavailable)
        }
        guard !Task.isCancelled else {
            return .failed(.unavailable)
        }
        guard let remainingTime = remainingTime(until: deadline, clock: clock) else {
            return .failed(.unavailable)
        }

        let result = await executor.run(
            arguments: [
                paths.script.path,
                paths.framework.path,
                "send",
                command.adapterIdentifier,
            ],
            timeout: remainingTime
        )
        switch result {
        case .success(0):
            return .sent
        case .success:
            return .failed(.commandRejected)
        case .failure:
            return .failed(.unavailable)
        }
    }

    private func currentTargetValidation(
        deadline: ContinuousClock.Instant,
        clock: ContinuousClock
    ) async -> PlaybackTargetValidation {
        guard let remainingTime = remainingTime(until: deadline, clock: clock) else {
            return .unavailable
        }

        do {
            for try await line in executor.lines(
                arguments: [
                    paths.script.path,
                    paths.framework.path,
                    "get",
                    "--no-artwork",
                ],
                initialOutputTimeout: remainingTime
            ) {
                return try MediaRemotePlaybackTargetDecoder().decode(line)
            }
        } catch {
            // 控制前复核失败只返回脱敏结果，不输出原始快照、stderr 或媒体内容。
        }
        return .unavailable
    }

    /// 来源复核与命令发送共享同一截止时间，避免两个串行阶段分别耗尽完整超时。
    private func remainingTime(
        until deadline: ContinuousClock.Instant,
        clock: ContinuousClock
    ) -> Duration? {
        let remainingTime = clock.now.duration(to: deadline)
        return remainingTime > .zero ? remainingTime : nil
    }
}

extension PlaybackControlCommand {
    fileprivate var adapterIdentifier: String {
        switch self {
        case .previousTrack:
            "5"
        case .togglePlayPause:
            "2"
        case .nextTrack:
            "4"
        }
    }
}
