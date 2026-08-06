import SwiftUI

/// 使用提取后的真实部件素材组合唱臂，并沿用原有落针轨迹和动画策略。
struct DesktopSceneMaterialTonearmView: View {
    let isEngaged: Bool
    let reduceMotion: Bool

    var body: some View {
        GeometryReader { proxy in
            let layout = DesktopSceneTonearmLayout(size: proxy.size)

            ZStack(alignment: .topLeading) {
                rotatingAssembly(layout: layout)
                    .rotationEffect(
                        .degrees(layout.rotationDegrees(isEngaged: isEngaged)),
                        anchor: UnitPoint(
                            x: layout.pivotPoint.x / proxy.size.width,
                            y: layout.pivotPoint.y / proxy.size.height
                        )
                    )

                pivot(layout: layout)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.45), value: isEngaged)
        }
    }

    private func rotatingAssembly(layout: DesktopSceneTonearmLayout) -> some View {
        ZStack(alignment: .topLeading) {
            tonearmTube(layout: layout)
            headshell(layout: layout)
            cartridge(layout: layout)
        }
        .frame(width: layout.size.width, height: layout.size.height)
    }

    @ViewBuilder
    private func pivot(layout: DesktopSceneTonearmLayout) -> some View {
        if let image = DesktopSceneTurntableAsset.pivot.image {
            image
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: layout.size.width * 0.7, height: layout.size.width * 0.7)
                .position(
                    x: layout.pivotPoint.x + layout.size.width * 0.08,
                    y: layout.pivotPoint.y + layout.size.width * 0.01
                )
                .shadow(color: .black.opacity(0.24), radius: 2, x: 2, y: 3)
        } else {
            Circle()
                .fill(Color(white: 0.13))
                .frame(width: layout.size.width * 0.6, height: layout.size.width * 0.6)
                .position(layout.pivotPoint)
        }
    }

    @ViewBuilder
    private func tonearmTube(layout: DesktopSceneTonearmLayout) -> some View {
        if let image = DesktopSceneTurntableAsset.tonearm.image {
            image
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(
                    width: layout.tubeLength,
                    height: layout.size.width * 0.52
                )
                .rotationEffect(.degrees(-90))
                .position(
                    x: layout.pivotPoint.x - layout.size.width * 0.01,
                    y: layout.pivotPoint.y + layout.tubeLength * 0.5
                )
                .shadow(color: .black.opacity(0.28), radius: 1.5, x: 1, y: 2)
        }
    }

    @ViewBuilder
    private func headshell(layout: DesktopSceneTonearmLayout) -> some View {
        if let image = DesktopSceneTurntableAsset.headshell.image {
            image
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(
                    width: layout.size.width * 0.46,
                    height: layout.size.height * 0.13
                )
                .rotationEffect(.degrees(-45))
                .position(
                    x: layout.tubeEndPoint.x - layout.size.width * 0.005,
                    y: layout.tubeEndPoint.y + layout.size.height * 0.045
                )
                .shadow(color: .black.opacity(0.24), radius: 1, x: 1, y: 1)
        }
    }

    @ViewBuilder
    private func cartridge(layout: DesktopSceneTonearmLayout) -> some View {
        if let image = DesktopSceneTurntableAsset.cartridge.image {
            image
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(
                    width: layout.size.width * 0.25,
                    height: layout.size.height * 0.065
                )
                .rotationEffect(.degrees(-45))
                .position(
                    x: layout.tubeEndPoint.x - layout.size.width * 0.01,
                    y: layout.tubeEndPoint.y + layout.size.height * 0.14
                )
                .shadow(color: .black.opacity(0.2), radius: 0.8, x: 1, y: 1)
        }
    }
}
