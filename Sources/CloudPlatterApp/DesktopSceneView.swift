import CloudPlatterCore
import SwiftUI

/// 在单块显示器上呈现完整唱机桌面，并根据窗口与会话状态控制动画。
struct DesktopSceneView: View {
    let nowPlayingState: NowPlayingState
    let isWindowVisible: Bool
    let isSessionActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var rotationState = RecordRotationState()

    private var presentation: DesktopScenePresentation {
        DesktopScenePresentation(state: nowPlayingState)
    }

    private var animationPolicy: DesktopSceneAnimationPolicy {
        DesktopSceneAnimationPolicy(
            isPlaybackActive: presentation.isRecordSpinning,
            isWindowVisible: isWindowVisible,
            isSessionActive: isSessionActive,
            reduceMotion: reduceMotion
        )
    }

    var body: some View {
        GeometryReader { proxy in
            let layout = DesktopSceneLayout(canvasSize: proxy.size)

            ZStack(alignment: .topLeading) {
                DesktopSceneWalnutBackground()

                metadata(layout: layout)
                    .frame(
                        width: layout.metadataFrame.width,
                        height: layout.metadataFrame.height,
                        alignment: .topLeading
                    )
                    .position(
                        x: layout.metadataFrame.midX,
                        y: layout.metadataFrame.midY
                    )

                DesktopSceneAlbumSleeveView(
                    content: DesktopSceneAlbumSleeveContent(presentation: presentation)
                )
                .frame(
                    width: layout.sleeveFrame.width,
                    height: layout.sleeveFrame.height
                )
                .rotationEffect(.degrees(-3))
                .position(
                    x: layout.sleeveFrame.midX,
                    y: layout.sleeveFrame.midY
                )

                DesktopSceneTurntableView(
                    artworkData: presentation.artworkData,
                    isRecordSpinning: presentation.isRecordSpinning,
                    shouldAnimate: animationPolicy.shouldAnimate,
                    reduceMotion: reduceMotion,
                    rotationAngle: rotationAngle
                )
                .frame(
                    width: layout.turntableFrame.width,
                    height: layout.turntableFrame.height
                )
                .position(
                    x: layout.turntableFrame.midX,
                    y: layout.turntableFrame.midY
                )
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("CloudPlatter 全屏动态唱机桌面")
        .onAppear {
            updateRotation(isActive: animationPolicy.shouldAnimate)
        }
        .onChange(of: animationPolicy.shouldAnimate) { _, isActive in
            updateRotation(isActive: isActive)
        }
    }

    private func metadata(layout: DesktopSceneLayout) -> some View {
        VStack(alignment: .leading, spacing: max(8, layout.canvasSize.height * 0.012)) {
            Text("CloudPlatter")
                .font(.system(size: max(12, layout.canvasSize.width * 0.009), weight: .semibold))
                .foregroundStyle(.white.opacity(0.72))

            Text(presentation.titleText)
                .font(
                    .system(
                        size: min(74, max(34, layout.canvasSize.width * 0.043)),
                        weight: .semibold,
                        design: .default
                    )
                )
                .tracking(-1.2)
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.72)

            Text(metadataSubtitle)
                .font(.system(size: min(21, max(14, layout.canvasSize.width * 0.012))))
                .foregroundStyle(.white.opacity(0.76))
                .lineLimit(1)

            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: layout.statusDiameter, height: layout.statusDiameter)
                    .shadow(color: statusColor.opacity(0.65), radius: 3)

                Text(presentation.statusText)
                    .font(.system(size: min(15, max(12, layout.canvasSize.width * 0.009))))
                    .foregroundStyle(.white.opacity(0.82))
            }
            .padding(.top, max(6, layout.canvasSize.height * 0.012))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .shadow(color: .black.opacity(0.34), radius: 2, y: 2)
    }

    private var metadataSubtitle: String {
        guard nowPlayingState.status == .playing || nowPlayingState.status == .paused else {
            return presentation.artistText
        }
        return "\(presentation.artistText) · \(presentation.albumText)"
    }

    private var statusColor: Color {
        presentation.isRecordSpinning
            ? Color(red: 0.83, green: 1, blue: 0.38) : .white.opacity(0.48)
    }

    private func rotationAngle(at date: Date) -> Angle {
        .degrees(rotationState.angle(at: date))
    }

    private func updateRotation(isActive: Bool) {
        let now = Date()
        if isActive {
            rotationState.start(at: now)
        } else {
            withAnimation(.easeOut(duration: 0.35)) {
                rotationState.stop(at: now)
            }
        }
    }
}
