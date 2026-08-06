import AppKit
import CloudPlatterCore
import Foundation
import SwiftUI
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

    @Test("全屏构图在 16 比 9、16 比 10 与超宽屏内保持主要物件边界")
    func fullScreenLayoutKeepsPrimaryObjectsInsideCanvas() {
        for canvasSize in [
            CGSize(width: 1_280, height: 720),
            CGSize(width: 1_440, height: 900),
            CGSize(width: 1_728, height: 720),
        ] {
            let layout = DesktopSceneLayout(
                canvasSize: canvasSize,
                metadataSubtitleWidth: canvasSize.width * 0.42
            )
            let canvas = CGRect(origin: .zero, size: canvasSize)

            #expect(canvas.contains(layout.turntableFrame))
            #expect(canvas.contains(layout.sleeveFrame))
            #expect(canvas.contains(layout.metadataFrame))
            #expect(canvas.contains(layout.playbackControlsFrame))
            #expect(canvas.contains(layout.metadataSubtitleFrame))
            #expect(layout.sleeveFrame.midX < layout.turntableFrame.midX)
            #expect(layout.metadataSubtitleFrame.maxX < layout.playbackControlsFrame.minX)
            #expect(!layout.playbackControlsFrame.intersects(layout.turntableFrame))

            let minimumTitleFont = layout.metadataTitleFontSize * 0.72
            let brandLineHeight = NSFont.systemFont(
                ofSize: layout.metadataBrandFontSize,
                weight: .semibold
            ).boundingRectForFont.height
            let titleLineHeight = NSFont.systemFont(
                ofSize: minimumTitleFont,
                weight: .semibold
            ).boundingRectForFont.height
            let requiredMetadataHeight =
                brandLineHeight
                + titleLineHeight * 2
                + layout.metadataSubtitleFrame.height
                + layout.metadataVerticalSpacing * 3
            #expect(layout.metadataFrame.height >= requiredMetadataHeight)
        }
    }

    @MainActor
    @Test("三种屏幕比例在一倍与二倍缩放下输出原生像素尺寸")
    func fullScreenSceneRendersAtNativePixelSizes() throws {
        let state = NowPlayingState(
            title: "匿名歌曲",
            artist: "匿名艺人",
            album: "匿名专辑",
            artwork: try makeAnonymousArtwork(pixelSide: 100),
            status: .paused
        )

        for canvasSize in [
            CGSize(width: 1_280, height: 720),
            CGSize(width: 1_440, height: 900),
            CGSize(width: 1_728, height: 720),
        ] {
            for scale in [CGFloat(1), CGFloat(2)] {
                let renderer = ImageRenderer(
                    content: DesktopSceneView(
                        nowPlayingState: state,
                        isWindowVisible: true,
                        isSessionActive: true
                    )
                    .frame(width: canvasSize.width, height: canvasSize.height)
                )
                renderer.proposedSize = ProposedViewSize(canvasSize)
                renderer.scale = scale

                let image = try #require(renderer.cgImage)
                #expect(image.width == Int(canvasSize.width * scale))
                #expect(image.height == Int(canvasSize.height * scale))
            }
        }
    }

    @Test("A 方案在 1440 乘 900 屏幕使用约定比例")
    func walnutLayoutUsesApprovedCompositionAtReferenceSize() {
        let layout = DesktopSceneLayout(
            canvasSize: CGSize(width: 1_440, height: 900),
            metadataSubtitleWidth: 300
        )

        #expect(abs(layout.turntableFrame.width - 806.4) < 0.01)
        #expect(abs(layout.turntableFrame.minX - 561.6) < 0.01)
        #expect(abs(layout.sleeveFrame.width - 446.4) < 0.01)
        #expect(abs(layout.sleeveFrame.minX - 100.8) < 0.01)
        #expect(abs(layout.metadataFrame.width - 1_180.8) < 0.01)
        #expect(abs(layout.playbackControlsFrame.height - 39.6) < 0.01)
        #expect(abs(layout.metadataSubtitleFrame.width - 300) < 0.01)
    }

    @Test("木纹资源以四千像素原图随 SwiftPM 目标分发")
    func walnutTextureShipsAtSourceResolution() throws {
        let url = try #require(DesktopSceneWalnutTexture.moduleResourceURL)
        let image = try #require(NSImage(contentsOf: url))
        let representation = try #require(image.representations.first)

        #expect(representation.pixelsWide >= 4_096)
        #expect(representation.pixelsHigh >= 4_096)
    }

    @Test("信息行按内容增长并在控制条前限制宽度")
    func metadataSubtitlePositionsPlaybackControls() {
        let canvasSize = CGSize(width: 1_440, height: 900)
        let shortLayout = DesktopSceneLayout(
            canvasSize: canvasSize,
            metadataSubtitleWidth: 80
        )
        let longLayout = DesktopSceneLayout(
            canvasSize: canvasSize,
            metadataSubtitleWidth: 420
        )

        #expect(abs(shortLayout.metadataSubtitleFrame.width - 160) < 0.01)
        #expect(abs(longLayout.metadataSubtitleFrame.width - 420) < 0.01)
        #expect(
            longLayout.playbackControlsFrame.minX
                > shortLayout.playbackControlsFrame.minX
        )
    }

    @Test("作者信息与播放控制紧跟在单行标题下方")
    func metadataInformationRowStaysCloseToTitle() {
        let canvasSize = CGSize(width: 1_440, height: 900)
        let layout = DesktopSceneLayout(
            canvasSize: canvasSize,
            titleText: "Summer (Tropicala)",
            subtitleText: "匿名艺人 · 匿名专辑"
        )

        #expect(layout.metadataSubtitleFrame.minY == layout.playbackControlsFrame.minY)
        #expect(layout.metadataTitleFrame.maxY < layout.metadataSubtitleFrame.minY)
        #expect(layout.playbackControlsFrame.minY - layout.metadataFrame.minY < 150)
        #expect(layout.playbackControlsFrame.maxY < layout.metadataFrame.maxY)
    }

    @Test("两行标题在矮屏幕上不会侵入作者与控制行")
    func multilineTitleDoesNotOverlapInformationRow() {
        for canvasSize in [
            CGSize(width: 1_280, height: 720),
            CGSize(width: 1_728, height: 720),
        ] {
            let layout = DesktopSceneLayout(
                canvasSize: canvasSize,
                titleText: "一首足够长并且会自然换成两行显示的匿名歌曲标题",
                subtitleText: "匿名艺人 · 匿名专辑"
            )

            #expect(
                layout.metadataTitleFrame.maxY + layout.metadataVerticalSpacing
                    <= layout.metadataSubtitleFrame.minY
            )
            #expect(layout.metadataSubtitleFrame.minY == layout.playbackControlsFrame.minY)
            #expect(layout.playbackControlsFrame.maxY <= layout.metadataFrame.maxY)
        }
    }

    @Test("唱臂播放时落在音槽并在停止时回到唱片外")
    func tonearmStylusMovesBetweenGrooveAndRest() {
        for canvasSize in [
            CGSize(width: 1_280, height: 720),
            CGSize(width: 1_440, height: 900),
            CGSize(width: 1_728, height: 720),
        ] {
            let sceneLayout = DesktopSceneLayout(canvasSize: canvasSize)
            let turntableLayout = DesktopSceneTurntableLayout(size: sceneLayout.turntableFrame.size)
            let engagedRadius = turntableLayout.stylusRadiusRatio(isEngaged: true)
            let restingRadius = turntableLayout.stylusRadiusRatio(isEngaged: false)

            #expect(engagedRadius > 0.65)
            #expect(engagedRadius < 0.82)
            #expect(restingRadius > 1.4)
        }
    }

    @Test("用户提供的唱机部件素材随 SwiftPM 目标分发")
    func turntableMaterialAssetsShipWithApplication() throws {
        for asset in DesktopSceneTurntableAsset.allCases {
            let url = try #require(asset.moduleResourceURL)
            let values = try url.resourceValues(forKeys: [.fileSizeKey])
            #expect((values.fileSize ?? 0) > 1_024)
        }
    }

    @Test("低分辨率封面按屏幕倍率保持原生像素尺寸")
    func lowResolutionArtworkUsesNativePixelSize() {
        for scale in [CGFloat(1), CGFloat(2)] {
            let layout = DesktopSceneAlbumSleeveLayout(
                sleeveSize: CGSize(width: 640, height: 640),
                artworkPixelSize: CGSize(width: 100, height: 100),
                displayScale: scale
            )

            #expect(abs(layout.artworkPlateSide - 307.2) < 0.01)
            #expect(abs(layout.artworkSide * scale - 100) < 0.01)
        }
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

    @MainActor
    @Test("播放控制层只接收按钮区域且不抢占键盘焦点")
    func playbackControlPanelIsInteractiveWithoutTakingFocus() {
        let panel = DesktopPlaybackControlPanel(
            contentRect: NSRect(x: 0, y: 0, width: 168, height: 48)
        )

        #expect(!panel.canBecomeKey)
        #expect(!panel.canBecomeMain)
        #expect(!panel.ignoresMouseEvents)
        #expect(
            panel.level.rawValue
                == Int(CGWindowLevelForKey(.desktopIconWindow)) + 1
        )
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

    @Test("减少动态效果时播放按钮按下不缩放")
    func reduceMotionDisablesPlaybackButtonScale() {
        let reduced = DesktopPlaybackControlAnimationPolicy(
            isPressed: true,
            reduceMotion: true
        )
        let standard = DesktopPlaybackControlAnimationPolicy(
            isPressed: true,
            reduceMotion: false
        )

        #expect(reduced.scale == 1)
        #expect(reduced.animationDuration == nil)
        #expect(standard.scale == 0.93)
        #expect(standard.animationDuration == 0.16)
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

    @MainActor
    private func makeAnonymousArtwork(pixelSide: Int) throws -> Data {
        let bitmap = try #require(
            NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: pixelSide,
                pixelsHigh: pixelSide,
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            )
        )
        return try #require(bitmap.representation(using: .png, properties: [:]))
    }
}
