import Foundation

/// 在播放命令发送前即时确认系统当前控制目标，失败时不得泄露原始媒体内容。
protocol PlaybackTargetValidating: Sendable {
    func validate(timeout: Duration) async -> PlaybackTargetValidation
}

/// 通过 Apple 签名的 JXA 宿主确认系统全局当前目标仍是网易云音乐。
struct JXAPlaybackTargetValidator: PlaybackTargetValidating, Sendable {
    private let responseFetcher: JXANowPlayingResponseFetcher

    init(paths: JXANowPlayingPaths, executor: any MediaRemoteProcessExecuting) {
        responseFetcher = JXANowPlayingResponseFetcher(paths: paths, executor: executor)
    }

    func validate(timeout: Duration) async -> PlaybackTargetValidation {
        guard let response = await responseFetcher.fetch(timeout: timeout) else {
            return .unavailable
        }
        return (try? JXANowPlayingResponseDecoder().decodePlaybackTarget(response))
            ?? .unavailable
    }
}
