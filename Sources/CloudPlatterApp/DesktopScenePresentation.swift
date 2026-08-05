import CloudPlatterCore
import Foundation

struct DesktopScenePresentation: Equatable {
    let artworkData: Data?
    let titleText: String
    let artistText: String
    let statusText: String
    let isRecordSpinning: Bool
    let usesPlaceholderArtwork: Bool

    init(state: NowPlayingState) {
        switch state.status {
        case .playing:
            artworkData = state.artwork
            titleText = state.title.nonEmpty ?? "当前曲目"
            artistText = state.artist.nonEmpty ?? "未知艺人"
            statusText = "正在播放"
            isRecordSpinning = true
            usesPlaceholderArtwork = state.artwork == nil
        case .paused:
            artworkData = state.artwork
            titleText = state.title.nonEmpty ?? "当前曲目"
            artistText = state.artist.nonEmpty ?? "未知艺人"
            statusText = "已暂停"
            isRecordSpinning = false
            usesPlaceholderArtwork = state.artwork == nil
        case .idle:
            artworkData = nil
            titleText = "等待网易云音乐"
            artistText = "播放后，唱片会出现在这里"
            statusText = "等待播放"
            isRecordSpinning = false
            usesPlaceholderArtwork = true
        case .unavailable:
            artworkData = nil
            titleText = "暂时无法读取播放状态"
            artistText = "你仍可正常使用网易云音乐"
            statusText = "暂不可用"
            isRecordSpinning = false
            usesPlaceholderArtwork = true
        }
    }
}
