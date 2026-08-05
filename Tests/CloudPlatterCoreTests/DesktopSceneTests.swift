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
        #expect(playing.albumText == "未知专辑")
        #expect(!playing.usesPlaceholderArtwork)
        #expect(idle.usesPlaceholderArtwork)
        #expect(!idle.isRecordSpinning)
        #expect(unavailable.usesPlaceholderArtwork)
        #expect(!unavailable.isRecordSpinning)
    }

    @Test("全屏构图在 16 比 10 与超宽屏内保持主要物件边界")
    func fullScreenLayoutKeepsPrimaryObjectsInsideCanvas() {
        for canvasSize in [
            CGSize(width: 1_440, height: 900),
            CGSize(width: 1_728, height: 720),
        ] {
            let layout = DesktopSceneLayout(canvasSize: canvasSize)
            let canvas = CGRect(origin: .zero, size: canvasSize)

            #expect(canvas.contains(layout.turntableFrame))
            #expect(canvas.contains(layout.sleeveFrame))
            #expect(canvas.contains(layout.metadataFrame))
            #expect(layout.sleeveFrame.midX < layout.turntableFrame.midX)
        }
    }

    @Test("A 方案在 1440 乘 900 屏幕使用约定比例")
    func walnutLayoutUsesApprovedCompositionAtReferenceSize() {
        let layout = DesktopSceneLayout(canvasSize: CGSize(width: 1_440, height: 900))

        #expect(abs(layout.turntableFrame.width - 806.4) < 0.01)
        #expect(abs(layout.turntableFrame.minX - 561.6) < 0.01)
        #expect(abs(layout.sleeveFrame.width - 446.4) < 0.01)
        #expect(abs(layout.sleeveFrame.minX - 100.8) < 0.01)
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

    @Test("窗口不可见、会话非活动或减少动态效果时停止刷新")
    func animationPolicyStopsUnnecessaryRefreshes() {
        let active = DesktopSceneAnimationPolicy(
            isPlaybackActive: true,
            isWindowVisible: true,
            isSessionActive: true,
            reduceMotion: false
        )

        #expect(active.shouldAnimate)
        #expect(
            !DesktopSceneAnimationPolicy(
                isPlaybackActive: true,
                isWindowVisible: false,
                isSessionActive: true,
                reduceMotion: false
            ).shouldAnimate
        )
        #expect(
            !DesktopSceneAnimationPolicy(
                isPlaybackActive: true,
                isWindowVisible: true,
                isSessionActive: false,
                reduceMotion: false
            ).shouldAnimate
        )
        #expect(
            !DesktopSceneAnimationPolicy(
                isPlaybackActive: true,
                isWindowVisible: true,
                isSessionActive: true,
                reduceMotion: true
            ).shouldAnimate
        )
    }

    @Test("唱片暂停后保留停止角度且不再刷新")
    func pausedRecordKeepsItsStoppingAngle() {
        let start = Date(timeIntervalSinceReferenceDate: 100)
        var rotation = RecordRotationState()

        rotation.start(at: start)
        #expect(rotation.angle(at: start.addingTimeInterval(1)) == 18)

        rotation.stop(at: start.addingTimeInterval(1))
        let stoppedAngle = rotation.angle(at: start.addingTimeInterval(2))

        #expect(!rotation.isAnimating)
        #expect(stoppedAngle == 24)
        #expect(rotation.angle(at: start.addingTimeInterval(60)) == stoppedAngle)
    }
}
