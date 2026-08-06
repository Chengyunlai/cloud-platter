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
            requestTimeout: .milliseconds(800)
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
        switch await currentTargetValidation() {
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

        let result = await executor.run(
            arguments: [
                paths.script.path,
                paths.framework.path,
                "send",
                command.adapterIdentifier,
            ],
            timeout: requestTimeout
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

    private func currentTargetValidation() async -> PlaybackTargetValidation {
        do {
            for try await line in executor.lines(
                arguments: [
                    paths.script.path,
                    paths.framework.path,
                    "get",
                    "--no-artwork",
                ],
                initialOutputTimeout: requestTimeout
            ) {
                return try MediaRemotePlaybackTargetDecoder().decode(line)
            }
        } catch {
            // 控制前复核失败只返回脱敏结果，不输出原始快照、stderr 或媒体内容。
        }
        return .unavailable
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
