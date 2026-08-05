/// 为界面提供规范化播放状态序列的最小边界。
///
/// 生产环境使用 `MediaRemoteObservationSource`；测试可以注入录制状态，避免依赖真实播放器。
/// 来源失败时必须发出 `.unavailable` 安全降级；不需要继续恢复时可以结束序列，不能把底层错误
/// 或原始媒体字段抛给界面。
public protocol PlaybackObservationSource: Sendable {
    func states() -> AsyncStream<NowPlayingState>
}

extension MediaRemoteObservationSource: PlaybackObservationSource {}
