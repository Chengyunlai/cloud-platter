import SwiftUI

@main
struct CloudPlatterApp: App {
    @StateObject private var playbackModel = PlaybackModel()

    var body: some Scene {
        MenuBarExtra {
            NowPlayingMenuView(nowPlayingState: playbackModel.nowPlayingState)
        } label: {
            let presentation = NowPlayingPresentation(state: playbackModel.nowPlayingState)

            Label(presentation.menuBarTitle, systemImage: presentation.symbolName)
                .labelStyle(.titleAndIcon)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(nowPlayingState: playbackModel.nowPlayingState)
        }
    }
}
