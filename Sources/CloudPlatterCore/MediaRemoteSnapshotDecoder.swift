import Foundation

/// 把 MediaRemote Adapter 的一次性完整 JSON 快照转换为规范化播放状态。
struct MediaRemoteSnapshotDecoder: Sendable {
    func decode(_ data: Data) throws -> NowPlayingState {
        let snapshot: [String: MediaRemoteJSONValue]
        do {
            snapshot = try JSONDecoder().decode(
                [String: MediaRemoteJSONValue].self,
                from: data
            )
        } catch {
            throw MediaRemoteStreamDecodingError.invalidEvent
        }
        return makeMediaRemoteNowPlayingState(from: snapshot)
    }
}

func makeMediaRemoteNowPlayingState(from snapshot: [String: MediaRemoteJSONValue])
    -> NowPlayingState
{
    guard !snapshot.isEmpty else {
        return .idle
    }

    let sourceBundleIdentifier = snapshot.string(for: "bundleIdentifier")
    guard
        sourceBundleIdentifier == SupportedMediaSource.neteaseMusicBundleIdentifier
    else {
        return .idle
    }

    guard let title = snapshot.string(for: "title"),
        let isPlaying = snapshot.bool(for: "playing")
    else {
        return NowPlayingState(
            sourceBundleIdentifier: sourceBundleIdentifier,
            status: .unavailable
        )
    }

    let playbackRate = snapshot.number(for: "playbackRate") ?? (isPlaying ? 1 : 0)

    return NowPlayingState(
        sourceBundleIdentifier: sourceBundleIdentifier,
        title: title,
        artist: snapshot.string(for: "artist"),
        album: snapshot.string(for: "album"),
        artwork: snapshot.string(for: "artworkData").flatMap { Data(base64Encoded: $0) },
        duration: snapshot.number(for: "duration"),
        elapsed: snapshot.number(for: "elapsedTime"),
        playbackRate: playbackRate,
        status: isPlaying ? .playing : .paused
    )
}

enum MediaRemoteJSONValue: Decodable, Equatable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: MediaRemoteJSONValue])
    case array([MediaRemoteJSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String: MediaRemoteJSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([MediaRemoteJSONValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "无法识别 JSON 值类型。"
            )
        }
    }
}

extension Dictionary where Key == String, Value == MediaRemoteJSONValue {
    fileprivate func string(for key: String) -> String? {
        guard case .string(let value) = self[key] else {
            return nil
        }
        return value
    }

    fileprivate func bool(for key: String) -> Bool? {
        guard case .bool(let value) = self[key] else {
            return nil
        }
        return value
    }

    fileprivate func number(for key: String) -> Double? {
        guard case .number(let value) = self[key] else {
            return nil
        }
        return value
    }
}
