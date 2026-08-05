import Foundation

/// 把 MediaRemote Adapter 的逐行 JSON 事件转换为规范化播放状态。
///
/// 解码器会在内存中合并上游的增量事件。调用方应为每条独立事件流创建一个实例，
/// 不能在多个 helper 进程之间复用同一份快照。
public struct MediaRemoteStreamDecoder: Sendable {
    private var snapshot: [String: MediaRemoteJSONValue] = [:]

    public init() {}

    /// 解码一行完整的 UTF-8 JSON，并返回该事件生效后的当前状态。
    public mutating func decode(line: Data) throws -> NowPlayingState {
        let event: StreamEvent
        do {
            event = try JSONDecoder().decode(StreamEvent.self, from: line)
        } catch {
            throw MediaRemoteDecodingError.invalidPayload
        }

        guard event.type == "data" else {
            throw MediaRemoteDecodingError.unsupportedEventType(event.type)
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

        return MediaRemoteNowPlayingStateMapper().map(snapshot)
    }
}

private struct StreamEvent: Decodable {
    let type: String
    let diff: Bool
    let payload: [String: MediaRemoteJSONValue]
}
