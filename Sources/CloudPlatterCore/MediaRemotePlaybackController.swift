import Foundation

/// 通过隔离的 MediaRemote Adapter 向当前网易云音乐发送用户主动播放命令。
public actor MediaRemotePlaybackController: PlaybackControlling {
    private let paths: MediaRemoteAdapterPaths
    private let executor: any MediaRemoteProcessExecuting
    private let fallbackTargetValidator: (any PlaybackTargetValidating)?
    private let requestTimeout: Duration

    public init() {
        let paths = MediaRemoteAdapterPaths.bundled()
        let jxaPaths = JXANowPlayingPaths.bundled()
        self.init(
            paths: paths,
            executor: FoundationMediaRemoteProcessExecutor(executable: paths.perlExecutable),
            fallbackTargetValidator: JXAPlaybackTargetValidator(
                paths: jxaPaths,
                executor: FoundationMediaRemoteProcessExecutor(
                    executable: jxaPaths.osascriptExecutable
                )
            ),
            requestTimeout: PlaybackControlTiming.requestTimeout
        )
    }

    init(
        paths: MediaRemoteAdapterPaths,
        executor: any MediaRemoteProcessExecuting,
        fallbackTargetValidator: (any PlaybackTargetValidating)? = nil,
        requestTimeout: Duration
    ) {
        self.paths = paths
        self.executor = executor
        self.fallbackTargetValidator = fallbackTargetValidator
        self.requestTimeout = requestTimeout
    }

    public func validateCurrentTarget() async -> PlaybackTargetValidation {
        guard paths.hasRequiredRuntimeResources() else {
            return .unavailable
        }
        return await currentTargetValidation(
            budget: PlaybackControlBudget(timeout: requestTimeout)
        )
    }

    public func send(_ command: PlaybackControlCommand) async -> PlaybackControlResult {
        guard paths.hasRequiredRuntimeResources() else {
            return .failed(.unavailable)
        }
        let budget = PlaybackControlBudget(timeout: requestTimeout)

        switch await currentTargetValidation(budget: budget) {
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
        guard let remainingTime = budget.remainingTime else {
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
        budget: PlaybackControlBudget
    ) async -> PlaybackTargetValidation {
        guard let remainingTime = budget.remainingTime else {
            return .unavailable
        }
        let validationTimeout = min(
            remainingTime,
            PlaybackControlTiming.mediaRemoteValidationTimeout
        )

        do {
            for try await line in executor.lines(
                arguments: [
                    paths.script.path,
                    paths.framework.path,
                    "get",
                    "--no-artwork",
                ],
                initialOutputTimeout: validationTimeout
            ) {
                let validation = try MediaRemotePlaybackTargetDecoder().decode(line)
                if validation != .unavailable {
                    return validation
                }
                break
            }
        } catch {
            // 控制前复核失败只返回脱敏结果，不输出原始快照、stderr 或媒体内容。
        }
        return await fallbackTargetValidation(budget: budget)
    }

    /// 普通应用无法读取系统快照时，复用网易云进程内的定向查询确认目标，仍不依据过期 UI 状态发送。
    private func fallbackTargetValidation(
        budget: PlaybackControlBudget
    ) async -> PlaybackTargetValidation {
        guard let fallbackTargetValidator,
            let remainingTime = budget.remainingTime
        else {
            return .unavailable
        }
        let validationTimeout = min(
            remainingTime,
            PlaybackControlTiming.fallbackValidationTimeout
        )

        let validation = await fallbackTargetValidator.validate(
            timeout: validationTimeout
        )
        guard budget.remainingTime != nil else {
            return .unavailable
        }
        return validation
    }
}

/// 把串行复核与命令发送约束在同一绝对截止时间内。
private struct PlaybackControlBudget: Sendable {
    private let clock: ContinuousClock
    private let deadline: ContinuousClock.Instant

    init(timeout: Duration) {
        let clock = ContinuousClock()
        self.clock = clock
        deadline = clock.now.advanced(by: timeout)
    }

    var remainingTime: Duration? {
        let remainingTime = clock.now.duration(to: deadline)
        return remainingTime > .zero ? remainingTime : nil
    }
}

extension PlaybackControlCommand {
    fileprivate var adapterIdentifier: String {
        switch self {
        case .previousTrack:
            "5"
        case .play:
            "0"
        case .pause:
            "1"
        case .togglePlayPause:
            "2"
        case .nextTrack:
            "4"
        }
    }
}
