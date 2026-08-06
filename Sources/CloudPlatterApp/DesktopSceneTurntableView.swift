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

                DesktopSceneTonearmView(isEngaged: isRecordSpinning, reduceMotion: reduceMotion)
                    .frame(width: layout.tonearmFrame.width, height: layout.tonearmFrame.height)
                    .position(x: layout.tonearmFrame.midX, y: layout.tonearmFrame.midY)

                speedControl(size: size)

                brandPlate(size: size)
            }
        }
        .shadow(color: .black.opacity(0.44), radius: 10, y: 16)
        .accessibilityLabel(artworkData == nil ? "默认唱机" : "使用当前封面的唱机")
    }

    /// 参考木质机身素材，在原播放盘边界内叠出木框和香槟色哑光面板。
    private func deckSurface(size: CGSize) -> some View {
        let cornerRadius = max(12, size.width * 0.022)
        let trimWidth = max(8, size.width * 0.018)

        return ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.34, green: 0.16, blue: 0.075),
                            Color(red: 0.18, green: 0.075, blue: 0.034),
                            Color(red: 0.42, green: 0.21, blue: 0.1),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(
                cornerRadius: max(8, cornerRadius - trimWidth * 0.36),
                style: .continuous
            )
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.9, green: 0.85, blue: 0.77),
                        Color(red: 0.76, green: 0.7, blue: 0.61),
                        Color(red: 0.64, green: 0.58, blue: 0.49),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: max(8, cornerRadius - trimWidth * 0.36),
                    style: .continuous
                )
                .strokeBorder(.white.opacity(0.34), lineWidth: 1)
            }
            .padding(trimWidth)

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(.black.opacity(0.38), lineWidth: 1.2)

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .inset(by: trimWidth * 0.45)
                .strokeBorder(.white.opacity(0.16), lineWidth: 0.8)
        }
        .allowsHitTesting(false)
    }

    /// 参考金色旋钮素材，保留原位置并加入拉丝层次、定位线和速度刻度。
    private func speedControl(size: CGSize) -> some View {
        let center = CGPoint(x: size.width * 0.89, y: size.height * 0.78)
        let diameter = size.width * 0.07

        return ZStack {
            Text("33")
                .position(x: center.x - diameter * 0.82, y: center.y - diameter * 0.54)
            Text("45")
                .position(x: center.x + diameter * 0.82, y: center.y - diameter * 0.54)

            ForEach([-1.0, 1.0], id: \.self) { direction in
                Circle()
                    .fill(.black.opacity(0.58))
                    .frame(width: max(2, diameter * 0.08), height: max(2, diameter * 0.08))
                    .position(
                        x: center.x + diameter * 0.72 * direction,
                        y: center.y - diameter * 0.18
                    )
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.96, green: 0.78, blue: 0.52),
                            Color(red: 0.67, green: 0.43, blue: 0.21),
                            Color(red: 0.3, green: 0.19, blue: 0.1),
                        ],
                        center: UnitPoint(x: 0.34, y: 0.28),
                        startRadius: 0,
                        endRadius: diameter * 0.56
                    )
                )
                .overlay {
                    Circle().strokeBorder(.black.opacity(0.54), lineWidth: max(1, diameter * 0.025))
                }
                .overlay(alignment: .top) {
                    Capsule()
                        .fill(.black.opacity(0.68))
                        .frame(width: max(1.5, diameter * 0.035), height: diameter * 0.24)
                        .padding(.top, diameter * 0.11)
                }
                .frame(width: diameter, height: diameter)
                .shadow(color: .black.opacity(0.3), radius: 3, y: 4)
                .position(center)
        }
        .frame(width: size.width, height: size.height)
        .font(.system(size: max(7, size.width * 0.01), weight: .medium, design: .rounded))
        .foregroundStyle(.black.opacity(0.7))
        .allowsHitTesting(false)
    }

    /// 参考黑金铭牌素材，用双行品牌标识替代悬浮文字块。
    private func brandPlate(size: CGSize) -> some View {
        let plateWidth = size.width * 0.17
        let plateHeight = size.height * 0.07

        return ZStack {
            RoundedRectangle(cornerRadius: max(2, plateHeight * 0.12), style: .continuous)
                .fill(Color(red: 0.17, green: 0.135, blue: 0.105))
                .overlay {
                    RoundedRectangle(
                        cornerRadius: max(2, plateHeight * 0.12),
                        style: .continuous
                    )
                    .strokeBorder(Color(red: 0.73, green: 0.53, blue: 0.28), lineWidth: 1)
                }

            VStack(spacing: max(1, plateHeight * 0.04)) {
                Text("CLOUD PLATTER")
                    .font(.system(size: max(6, size.width * 0.009), weight: .semibold))
                    .tracking(1)
                Text("BELT DRIVE")
                    .font(.system(size: max(4, size.width * 0.0058), weight: .medium))
                    .tracking(0.8)
                    .opacity(0.72)
            }
            .foregroundStyle(Color(red: 0.91, green: 0.72, blue: 0.44))

            HStack {
                Circle()
                Spacer()
                Circle()
            }
            .foregroundStyle(Color(red: 0.73, green: 0.53, blue: 0.28))
            .frame(width: plateWidth * 0.88)
            .frame(height: max(2, plateHeight * 0.08))
        }
        .frame(width: plateWidth, height: plateHeight)
        .shadow(color: .black.opacity(0.24), radius: 2, y: 2)
        .position(x: size.width * 0.89, y: size.height * 0.94)
        .allowsHitTesting(false)
    }
}
