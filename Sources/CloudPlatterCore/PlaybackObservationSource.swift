/// 为界面提供规范化播放状态序列的最小边界。
///
/// 生产环境使用 `MediaRemoteObservationSource`；测试可以注入录制状态，避免依赖真实播放器。
public protocol PlaybackObservationSource: Sendable {
    func states() -> AsyncStream<NowPlayingState>
}

extension MediaRemoteObservationSource: PlaybackObservationSource {}
