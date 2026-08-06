import Foundation

/// 把 JXA 定向查询结果转换为规范化播放状态。
///
/// 解码器只接受网易云音乐候选项；响应不完整或字段格式变化时返回不可用状态，避免把其他
/// 播放器或损坏数据送入界面。
struct JXANowPlayingResponseDecoder: Sendable {
    private static let globalCandidateSource = "global"
    private static let supportedCandidateSource = "supported"

    func decode(_ data: Data) throws -> NowPlayingState {
        let response = try JSONDecoder().decode(Response.self, from: data)
        guard response.complete else {
            return NowPlayingState(status: .unavailable)
        }

        let candidates = response.candidates.filter {
            $0.bundleIdentifier == SupportedMediaSource.neteaseMusicBundleIdentifier
        }
        guard
            let candidate = candidates.first(where: {
                $0.source == Self.supportedCandidateSource
            })
                ?? candidates.first
        else {
            return .idle
        }
        guard let title = candidate.title?.nonEmpty,
            let isPlaying = candidate.playing
        else {
            return NowPlayingState(
                sourceBundleIdentifier: SupportedMediaSource.neteaseMusicBundleIdentifier,
                status: .unavailable
            )
        }

        return NowPlayingState(
            sourceBundleIdentifier: SupportedMediaSource.neteaseMusicBundleIdentifier,
            title: title,
            artist: candidate.artist?.nonEmpty,
            album: candidate.album?.nonEmpty,
            artwork: candidate.artworkData.flatMap { Data(base64Encoded: $0) },
            duration: candidate.duration,
            elapsed: candidate.elapsedTime,
            playbackRate: candidate.playbackRate ?? (isPlaying ? 1 : 0),
            status: isPlaying ? .playing : .paused
        )
    }

    /// 播放控制只能接受系统全局当前目标，不能用网易云自身残留的 player-scoped 状态代替。
    func decodePlaybackTarget(_ data: Data) throws -> PlaybackTargetValidation {
        let response = try JSONDecoder().decode(Response.self, from: data)
        guard response.complete,
            let candidate = response.candidates.first(where: {
                $0.source == Self.globalCandidateSource
            })
        else {
            return .unavailable
        }
        guard
            candidate.bundleIdentifier
                == SupportedMediaSource.neteaseMusicBundleIdentifier
        else {
            return .unsupported
        }
        guard candidate.title?.nonEmpty != nil, candidate.playing != nil else {
            return .unavailable
        }
        return .supported
    }
}

private struct Response: Decodable {
    let candidates: [Candidate]
    let complete: Bool
}

private struct Candidate: Decodable {
    let source: String
    let bundleIdentifier: String?
    let title: String?
    let artist: String?
    let album: String?
    let artworkData: String?
    let duration: Double?
    let elapsedTime: Double?
    let playbackRate: Double?
    let playing: Bool?
}

extension String {
    fileprivate var nonEmpty: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
