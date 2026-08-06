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
                RoundedRectangle(cornerRadius: max(12, size.width * 0.022), style: .continuous)
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
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: max(12, size.width * 0.022),
                            style: .continuous
                        )
                        .strokeBorder(.white.opacity(0.34), lineWidth: 1)
                    }

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

                DesktopSceneTonearmView(isEngaged: isRecordSpinning, reduceMotion: reduceMotion)
                    .frame(width: layout.tonearmFrame.width, height: layout.tonearmFrame.height)
                    .position(x: layout.tonearmFrame.midX, y: layout.tonearmFrame.midY)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.66, green: 0.55, blue: 0.39),
                                Color(red: 0.24, green: 0.2, blue: 0.15),
                            ],
                            center: UnitPoint(x: 0.38, y: 0.3),
                            startRadius: 0,
                            endRadius: size.width * 0.04
                        )
                    )
                    .frame(width: size.width * 0.07, height: size.width * 0.07)
                    .shadow(color: .black.opacity(0.32), radius: 4, y: 4)
                    .position(x: size.width * 0.89, y: size.height * 0.78)

                Text("CLOUD PLATTER")
                    .font(.system(size: max(6, size.width * 0.011), weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(.white.opacity(0.72))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 5)
                    .background(Color(red: 0.26, green: 0.25, blue: 0.23))
                    .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                    .position(x: size.width * 0.9, y: size.height * 0.94)
            }
        }
        .shadow(color: .black.opacity(0.44), radius: 10, y: 16)
        .accessibilityLabel(artworkData == nil ? "默认唱机" : "使用当前封面的唱机")
    }
}
