import Foundation

/// 定义一次性播放快照读取边界；实现不能建立自己的轮询，也不能泄露原始媒体内容或底层错误。
protocol NowPlayingSnapshotFetching: Sendable {
    /// 返回一次规范化状态；启动、超时或解析失败必须脱敏为不可用状态。
    func fetch() async -> NowPlayingState
}

/// 通过 Apple 签名的 `osascript` 对网易云音乐执行一次定向 MediaRemote 查询。
///
/// 每次调用都有首包超时并在返回后结束子进程；本类型不自行建立轮询，也不记录原始输出。
struct JXANowPlayingSnapshotSource: NowPlayingSnapshotFetching, Sendable {
    private let paths: JXANowPlayingPaths
    private let executor: any MediaRemoteProcessExecuting
    private let requestTimeout: Duration

    init() {
        let paths = JXANowPlayingPaths.bundled()
        self.init(
            paths: paths,
            executor: FoundationMediaRemoteProcessExecutor(
                executable: paths.osascriptExecutable
            ),
            requestTimeout: .seconds(2)
        )
    }

    init(
        paths: JXANowPlayingPaths,
        executor: any MediaRemoteProcessExecuting,
        requestTimeout: Duration
    ) {
        self.paths = paths
        self.executor = executor
        self.requestTimeout = requestTimeout
    }

    func fetch() async -> NowPlayingState {
        let fileManager = FileManager.default
        guard fileManager.isExecutableFile(atPath: paths.osascriptExecutable.path),
            fileManager.fileExists(atPath: paths.script.path)
        else {
            return NowPlayingState(status: .unavailable)
        }

        do {
            for try await line in executor.lines(
                arguments: [
                    "-l", "JavaScript", paths.script.path, "--",
                    SupportedMediaSource.neteaseMusicBundleIdentifier,
                ],
                initialOutputTimeout: requestTimeout
            ) {
                return try JXANowPlayingResponseDecoder().decode(line)
            }
        } catch {
            // 备用源失败只返回脱敏状态，不记录脚本输出、stderr 或用户媒体信息。
        }
        return NowPlayingState(status: .unavailable)
    }
}
