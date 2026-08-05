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
        let nowPlayingPresentation = NowPlayingPresentation(state: state)
        artworkData = state.artwork
        titleText = nowPlayingPresentation.titleText
        artistText =
            nowPlayingPresentation.showsMetadata
            ? nowPlayingPresentation.artistText
            : nowPlayingPresentation.guidanceText
        statusText = nowPlayingPresentation.statusText
        isRecordSpinning = state.status == .playing
        usesPlaceholderArtwork = state.artwork == nil
    }
}
