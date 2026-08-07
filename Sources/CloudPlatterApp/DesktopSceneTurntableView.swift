import Foundation
import SwiftUI

/// 组合唱盘、唱臂和实体控制件，形成桌面右侧的完整唱机。
struct DesktopSceneTurntableView: View {
    let artworkData: Data?
    let isRecordSpinning: Bool
    let shouldAnimate: Bool
    let reduceMotion: Bool
    let rotationAngle: (Date) -> Angle

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let layout = DesktopSceneTurntableLayout(size: size)

            ZStack(alignment: .topLeading) {
                deckSurface(size: size)

                TimelineView(
                    .animation(
                        minimumInterval: 1.0 / 30.0,
                        paused: !shouldAnimate
                    )
                ) { context in
                    DesktopSceneVinylRecordView(artworkData: artworkData)
                        .frame(width: layout.recordDiameter, height: layout.recordDiameter)
                        .rotationEffect(rotationAngle(context.date))
                }
                .position(x: layout.recordCenter.x, y: layout.recordCenter.y)

                DesktopSceneMaterialTonearmView(
                    turntableLayout: layout,
                    isEngaged: isRecordSpinning,
                    reduceMotion: reduceMotion
                )
                .frame(width: size.width, height: size.height)

                speedKnob(layout: layout)

                brandPlaque(layout: layout)
            }
        }
        .shadow(color: .black.opacity(0.44), radius: 10, y: 16)
        .accessibilityLabel(artworkData == nil ? "默认唱机" : "使用当前封面的唱机")
    }

    @ViewBuilder
    private func deckSurface(size: CGSize) -> some View {
        let cornerRadius = max(12, size.width * 0.022)

        if let image = DesktopSceneTurntableAsset.deck.image {
            image
                .resizable()
                .interpolation(.high)
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.91, green: 0.88, blue: 0.81),
                            Color(red: 0.69, green: 0.66, blue: 0.58),
                            Color(red: 0.53, green: 0.5, blue: 0.44),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    @ViewBuilder
    private func speedKnob(layout: DesktopSceneTurntableLayout) -> some View {
        let frame = layout.speedKnobFrame

        if let image = DesktopSceneTurntableAsset.knob.image {
            image
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: frame.width, height: frame.height)
                .position(x: frame.midX, y: frame.midY)
                .shadow(color: .black.opacity(0.25), radius: 3, y: 3)
        } else {
            Circle()
                .fill(Color(red: 0.46, green: 0.34, blue: 0.21))
                .frame(width: frame.width * 0.82, height: frame.height * 0.82)
                .position(x: frame.midX, y: frame.midY)
        }
    }

    @ViewBuilder
    private func brandPlaque(layout: DesktopSceneTurntableLayout) -> some View {
        let frame = layout.brandPlaqueFrame

        if let image = DesktopSceneTurntableAsset.plaque.image {
            image
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: frame.width, height: frame.height)
                .position(x: frame.midX, y: frame.midY)
                .shadow(color: .black.opacity(0.22), radius: 2, y: 2)
        } else {
            Text("CLOUD PLATTER")
                .font(.system(size: max(6, layout.size.width * 0.011), weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.72))
                .padding(.horizontal, 7)
                .padding(.vertical, 5)
                .background(Color(red: 0.26, green: 0.25, blue: 0.23))
                .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                .position(x: frame.midX, y: frame.midY)
        }
    }
}
