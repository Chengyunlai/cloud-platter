import Foundation

/// 集中把 MediaRemote 私有字段映射为应用公开的播放状态。
struct MediaRemoteNowPlayingStateMapper: Sendable {
    func map(_ snapshot: [String: MediaRemoteJSONValue]) -> NowPlayingState {
        guard !snapshot.isEmpty else {
            return .idle
        }

        let sourceBundleIdentifier = snapshot.mediaRemoteString(for: "bundleIdentifier")
        guard
            sourceBundleIdentifier == SupportedMediaSource.neteaseMusicBundleIdentifier
        else {
            return .idle
        }

        guard let title = snapshot.mediaRemoteString(for: "title"),
            let isPlaying = snapshot.mediaRemoteBool(for: "playing")
        else {
            return NowPlayingState(
                sourceBundleIdentifier: sourceBundleIdentifier,
                status: .unavailable
            )
        }

        let playbackRate =
            snapshot.mediaRemoteNumber(for: "playbackRate") ?? (isPlaying ? 1 : 0)

        return NowPlayingState(
            sourceBundleIdentifier: sourceBundleIdentifier,
            title: title,
            artist: snapshot.mediaRemoteString(for: "artist"),
            album: snapshot.mediaRemoteString(for: "album"),
            artwork: snapshot.mediaRemoteString(for: "artworkData").flatMap {
                Data(base64Encoded: $0)
            },
            duration: snapshot.mediaRemoteNumber(for: "duration"),
            elapsed: snapshot.mediaRemoteNumber(for: "elapsedTime"),
            playbackRate: playbackRate,
            status: isPlaying ? .playing : .paused
        )
    }
}
