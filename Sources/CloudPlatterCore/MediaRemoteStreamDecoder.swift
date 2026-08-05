import Foundation

/// 描述实时 MediaRemote 事件无法转换为规范化状态的原因。
public enum MediaRemoteStreamDecodingError: Error, Equatable, Sendable {
    case invalidEvent
    case unsupportedEventType(String)
}

/// 把 MediaRemote Adapter 的逐行 JSON 事件转换为规范化播放状态。
///
/// 解码器会在内存中合并上游的增量事件。调用方应为每条独立事件流创建一个实例，
/// 不能在多个 helper 进程之间复用同一份快照。
public struct MediaRemoteStreamDecoder: Sendable {
    private static let supportedBundleIdentifier = "com.netease.163music"

    private var snapshot: [String: JSONValue] = [:]

    public init() {}

    /// 解码一行完整的 UTF-8 JSON，并返回该事件生效后的当前状态。
    public mutating func decode(line: Data) throws -> NowPlayingState {
        let event: StreamEvent
        do {
            event = try JSONDecoder().decode(StreamEvent.self, from: line)
        } catch {
            throw MediaRemoteStreamDecodingError.invalidEvent
        }

        guard event.type == "data" else {
            throw MediaRemoteStreamDecodingError.unsupportedEventType(event.type)
        }

        if event.diff {
            for (key, value) in event.payload {
                if value == .null {
                    snapshot.removeValue(forKey: key)
                } else {
                    snapshot[key] = value
                }
            }
        } else {
            snapshot = event.payload.filter { $0.value != .null }
        }

        return makeState()
    }

    private func makeState() -> NowPlayingState {
        guard !snapshot.isEmpty else {
            return .idle
        }

        let sourceBundleIdentifier = snapshot.string(for: "bundleIdentifier")
        guard sourceBundleIdentifier == Self.supportedBundleIdentifier else {
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
}

private struct StreamEvent: Decodable {
    let type: String
    let diff: Bool
    let payload: [String: JSONValue]
}

private enum JSONValue: Decodable, Equatable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
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
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "无法识别 JSON 值类型。"
            )
        }
    }
}

extension Dictionary where Key == String, Value == JSONValue {
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
