import Foundation

/// 表示 CloudPlatter 已经规范化的当前媒体状态。
///
/// 可选字段允许播放来源缺少部分元数据；调用方必须根据 `status` 和实际字段安全降级，
/// 不能假定标题、封面、时长或进度始终存在。
public struct NowPlayingState: Equatable, Sendable {
    /// 描述当前媒体是否可展示及其播放状态，不暴露 MediaRemote 的原始取值。
    public enum PlaybackStatus: Equatable, Sendable {
        case idle
        case playing
        case paused
        case unavailable
    }

    public let sourceBundleIdentifier: String?
    public let title: String?
    public let artist: String?
    public let album: String?
    public let artwork: Data?
    public let duration: TimeInterval?
    public let elapsed: TimeInterval?
    public let playbackRate: Double
    public let status: PlaybackStatus

    public init(
        sourceBundleIdentifier: String? = nil,
        title: String? = nil,
        artist: String? = nil,
        album: String? = nil,
        artwork: Data? = nil,
        duration: TimeInterval? = nil,
        elapsed: TimeInterval? = nil,
        playbackRate: Double = 0,
        status: PlaybackStatus
    ) {
        self.sourceBundleIdentifier = sourceBundleIdentifier
        self.title = title
        self.artist = artist
        self.album = album
        self.artwork = artwork
        self.duration = duration
        self.elapsed = elapsed
        self.playbackRate = playbackRate
        self.status = status
    }

    /// 没有受支持媒体时使用的安全默认状态。
    public static let idle = NowPlayingState(status: .idle)
}
