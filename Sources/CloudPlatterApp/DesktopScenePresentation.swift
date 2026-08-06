import CloudPlatterCore
import Foundation

struct DesktopScenePresentation: Equatable {
    let artworkData: Data?
    let titleText: String
    let artistText: String
    let albumText: String
    let subtitleText: String
    let isRecordSpinning: Bool
    let usesPlaceholderArtwork: Bool
    let hasDisplayableMedia: Bool

    init(state: NowPlayingState) {
        let nowPlayingPresentation = NowPlayingPresentation(state: state)
        artworkData = state.artwork
        titleText = nowPlayingPresentation.titleText
        artistText =
            nowPlayingPresentation.showsMetadata
            ? nowPlayingPresentation.artistText
            : nowPlayingPresentation.guidanceText
        albumText = nowPlayingPresentation.albumText
        subtitleText =
            state.status == .playing || state.status == .paused
            ? "\(artistText) · \(albumText)"
            : artistText
        isRecordSpinning = state.status == .playing
        usesPlaceholderArtwork = state.artwork == nil
        hasDisplayableMedia = state.status == .playing || state.status == .paused
    }
}
