import Foundation

/// 用户可以从 CloudPlatter 主动发送的有限播放命令。
public enum PlaybackControlCommand: Equatable, Sendable {
    case previousTrack
    case togglePlayPause
    case nextTrack
}

/// 播放控制无法执行时返回的脱敏原因。
public enum PlaybackControlFailure: Equatable, Sendable {
    case unavailable
    case unsupportedSource
    case commandRejected
}

/// 描述一次用户主动播放控制是否已被系统接受。
public enum PlaybackControlResult: Equatable, Sendable {
    case sent
    case failed(PlaybackControlFailure)
}

/// 隔离播放命令发送边界；实现必须在发送前确认当前目标仍是网易云音乐。
public protocol PlaybackControlling: Sendable {
    func send(_ command: PlaybackControlCommand) async -> PlaybackControlResult
}
