import SwiftUI

@MainActor
@main
struct CloudPlatterApp: App {
    @StateObject private var playbackModel: PlaybackModel
    @StateObject private var desktopSceneController: DesktopSceneController
    @StateObject private var launchAtLoginModel: LaunchAtLoginModel
    @StateObject private var desktopSceneSettings: DesktopSceneSettings

    init() {
        let playbackModel = PlaybackModel()
        let desktopSceneSettings = DesktopSceneSettings()
        _desktopSceneSettings = StateObject(wrappedValue: desktopSceneSettings)
        _playbackModel = StateObject(wrappedValue: playbackModel)
        _desktopSceneController = StateObject(
            wrappedValue: DesktopSceneController(
                playbackModel: playbackModel, settings: desktopSceneSettings
            )
        )
        _launchAtLoginModel = StateObject(wrappedValue: LaunchAtLoginModel())
    }

    var body: some Scene {
        MenuBarExtra {
            NowPlayingMenuView(
                nowPlayingState: playbackModel.nowPlayingState,
                desktopSceneSettings: desktopSceneSettings
            )
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
            SettingsView(
                nowPlayingState: playbackModel.nowPlayingState,
                launchAtLoginModel: launchAtLoginModel,
                desktopSceneSettings: desktopSceneSettings
            )
        }
    }
}
