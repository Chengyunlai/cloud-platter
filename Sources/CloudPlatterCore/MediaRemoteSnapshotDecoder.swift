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
            throw MediaRemoteDecodingError.invalidPayload
        }
        return MediaRemoteNowPlayingStateMapper().map(snapshot)
    }
}
