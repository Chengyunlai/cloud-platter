import Foundation

/// 通过隔离的 MediaRemote Adapter 执行一次性只读查询，供长驻事件流停更时自愈。
struct MediaRemoteNowPlayingSnapshotSource: NowPlayingSnapshotFetching, Sendable {
    private let paths: MediaRemoteAdapterPaths
    private let executor: any MediaRemoteProcessExecuting
    private let requestTimeout: Duration

    init() {
        let paths = MediaRemoteAdapterPaths.bundled()
        self.init(
            paths: paths,
            executor: FoundationMediaRemoteProcessExecutor(executable: paths.perlExecutable),
            requestTimeout: .seconds(2)
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

    func fetch() async -> NowPlayingState {
        guard hasRequiredResources else {
            return NowPlayingState(status: .unavailable)
        }

        do {
            for try await line in executor.lines(
                arguments: [
                    paths.script.path,
                    paths.framework.path,
                    "get",
                ],
                initialOutputTimeout: requestTimeout
            ) {
                return try MediaRemoteSnapshotDecoder().decode(line)
            }
        } catch {
            // 一次性查询失败只返回脱敏状态，不记录原始输出、stderr 或用户媒体信息。
        }
        return NowPlayingState(status: .unavailable)
    }

    private var hasRequiredResources: Bool {
        let fileManager = FileManager.default
        return fileManager.isExecutableFile(atPath: paths.perlExecutable.path)
            && fileManager.fileExists(atPath: paths.script.path)
            && fileManager.fileExists(atPath: paths.framework.path)
    }
}
