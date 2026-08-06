import Foundation

/// 只验证播放命令目标，不把其他播放器的原始字段转换为应用状态。
struct MediaRemotePlaybackTargetDecoder: Sendable {
    func decode(_ data: Data) throws -> PlaybackTargetValidation {
        let snapshot = try JSONDecoder().decode(
            [String: MediaRemoteJSONValue].self,
            from: data
        )
        guard
            let sourceBundleIdentifier = snapshot.mediaRemoteString(for: "bundleIdentifier")
        else {
            return .unavailable
        }
        guard
            sourceBundleIdentifier == SupportedMediaSource.neteaseMusicBundleIdentifier
        else {
            return .unsupported
        }
        guard snapshot.mediaRemoteString(for: "title") != nil,
            snapshot.mediaRemoteBool(for: "playing") != nil
        else {
            return .unavailable
        }
        return .supported
    }
}
