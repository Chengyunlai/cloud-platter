import Foundation

/// 集中管理播放控制的底层请求与界面响应预算，避免两层单独调参后失去顺序关系。
public enum PlaybackControlTiming {
    /// 为主 MediaRemote 复核设置短上限，读取受限时仍给定向复核和命令发送留下时间。
    public static let mediaRemoteValidationTimeout = Duration.milliseconds(200)
    /// JXA 定向复核只读取当前目标，不得耗尽整次控制预算。
    public static let fallbackValidationTimeout = Duration.milliseconds(400)
    /// MediaRemote 子进程应在界面兜底前返回，给 UI 留出清理 pending 的余量。
    public static let requestTimeout = Duration.milliseconds(800)
    public static let responseDeadline = Duration.milliseconds(900)
}

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

/// 播放命令发送前对系统全局当前目标的即时复核结果。
public enum PlaybackTargetValidation: Equatable, Sendable {
    /// 已确认系统全局当前目标是可展示的网易云媒体。
    case supported
    /// 已确认系统全局当前目标不是网易云音乐或没有网易云媒体。
    case unsupported
    /// 资源缺失、查询失败、取消或超时，无法安全判断当前目标。
    case unavailable
}

/// 隔离播放命令发送边界；实现必须在发送前确认当前目标仍是网易云音乐。
public protocol PlaybackControlling: Sendable {
    /// 只读复核当前全局目标，供来源变化后安全恢复控制能力；失败、取消或超时必须返回不可用。
    func validateCurrentTarget() async -> PlaybackTargetValidation
    func send(_ command: PlaybackControlCommand) async -> PlaybackControlResult
}
