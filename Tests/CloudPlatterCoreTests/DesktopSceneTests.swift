import AppKit
import CloudPlatterCore
import Foundation
import Testing

@testable import CloudPlatterApp

@Suite("桌面唱片场景")
struct DesktopSceneTests {
    @Test("录制事件只在播放状态驱动唱片旋转")
    func recordedFixtureControlsRecordRotation() throws {
        let fixtureURL = try #require(
            Bundle.module.url(
                forResource: "netease-stream",
                withExtension: "ndjson",
                subdirectory: "Fixtures"
            )
        )
        let fixture = try String(contentsOf: fixtureURL, encoding: .utf8)
        var decoder = MediaRemoteStreamDecoder()
        var presentations: [DesktopScenePresentation] = []

        for line in fixture.split(whereSeparator: \.isNewline) {
            let state = try decoder.decode(line: Data(line.utf8))
            presentations.append(DesktopScenePresentation(state: state))
        }

        #expect(presentations.map(\.isRecordSpinning) == [true, false, true])
        #expect(presentations.map(\.titleText) == ["匿名歌曲一", "匿名歌曲一", "匿名歌曲二"])
    }

    @Test("封面缺失与不可用状态使用稳定的默认视觉")
    func missingArtworkAndUnavailableStateUseFallbackVisuals() {
        let artwork = Data([1, 2, 3])
        let playing = DesktopScenePresentation(
            state: NowPlayingState(
                title: "匿名歌曲",
                artist: "匿名艺人",
                artwork: artwork,
                status: .playing
            )
        )
        let idle = DesktopScenePresentation(state: .idle)
        let unavailable = DesktopScenePresentation(
            state: NowPlayingState(status: .unavailable)
        )

        #expect(playing.artworkData == artwork)
        #expect(!playing.usesPlaceholderArtwork)
        #expect(idle.usesPlaceholderArtwork)
        #expect(!idle.isRecordSpinning)
        #expect(unavailable.usesPlaceholderArtwork)
        #expect(!unavailable.isRecordSpinning)
    }

    @MainActor
    @Test("桌面窗口不会成为主窗口或抢占键盘焦点")
    func desktopWindowDoesNotTakeFocus() {
        let panel = DesktopScenePanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 320)
        )

        #expect(!panel.canBecomeKey)
        #expect(!panel.canBecomeMain)
        #expect(panel.ignoresMouseEvents)
    }
}
