import SwiftUI

@MainActor
@main
struct CloudPlatterApp: App {
    @StateObject private var playbackModel: PlaybackModel
    @StateObject private var desktopSceneController: DesktopSceneController

    init() {
        let playbackModel = PlaybackModel()
        _playbackModel = StateObject(wrappedValue: playbackModel)
        _desktopSceneController = StateObject(
            wrappedValue: DesktopSceneController(playbackModel: playbackModel)
        )
    }

    var body: some Scene {
        MenuBarExtra {
            NowPlayingMenuView(nowPlayingState: playbackModel.nowPlayingState)
        } label: {
            let presentation = NowPlayingPresentation(state: playbackModel.nowPlayingState)

            Label(presentation.menuBarTitle, systemImage: presentation.symbolName)
                .labelStyle(.titleAndIcon)
                .onAppear {
                    desktopSceneController.show()
                }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(nowPlayingState: playbackModel.nowPlayingState)
        }
    }
}
