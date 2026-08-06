import Foundation

/// 统一执行一次网易云定向 JXA 查询；只在内存中返回单行响应，不记录媒体内容或底层错误。
struct JXANowPlayingResponseFetcher: Sendable {
    private let paths: JXANowPlayingPaths
    private let executor: any MediaRemoteProcessExecuting

    init(paths: JXANowPlayingPaths, executor: any MediaRemoteProcessExecuting) {
        self.paths = paths
        self.executor = executor
    }

    func fetch(timeout: Duration) async -> Data? {
        let fileManager = FileManager.default
        guard fileManager.isExecutableFile(atPath: paths.osascriptExecutable.path),
            fileManager.fileExists(atPath: paths.script.path)
        else {
            return nil
        }

        do {
            for try await line in executor.lines(
                arguments: [
                    "-l", "JavaScript", paths.script.path, "--",
                    SupportedMediaSource.neteaseMusicBundleIdentifier,
                ],
                initialOutputTimeout: timeout
            ) {
                return line
            }
        } catch {
            // 查询失败只返回空响应，不记录脚本输出、stderr 或用户媒体内容。
        }
        return nil
    }
}
