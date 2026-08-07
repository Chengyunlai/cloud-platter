import SwiftUI

/// 使用两张完整真实素材呈现唱臂：固定底座静止，唱臂总成整体旋转。
struct DesktopSceneMaterialTonearmView: View {
    let turntableLayout: DesktopSceneTurntableLayout
    let isEngaged: Bool
    let reduceMotion: Bool

    var body: some View {
        let frame = turntableLayout.tonearmFrame
        let layout = DesktopSceneMaterialTonearmLayout(size: frame.size)
        let pivotPoint = CGPoint(
            x: frame.minX + layout.pivotPoint.x,
            y: frame.minY + layout.pivotPoint.y
        )
        let pivotBaseFrame = layout.pivotBaseFrame.offsetBy(dx: frame.minX, dy: frame.minY)

        ZStack(alignment: .topLeading) {
            pivotBase(layout: layout, frame: pivotBaseFrame, pivotPoint: pivotPoint)
            rotatingArm(layout: layout, pivotPoint: pivotPoint)
        }
        .frame(width: turntableLayout.size.width, height: turntableLayout.size.height)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.45), value: isEngaged)
    }

    @ViewBuilder
    private func pivotBase(
        layout: DesktopSceneMaterialTonearmLayout,
        frame: CGRect,
        pivotPoint: CGPoint
    ) -> some View {
        if let image = DesktopSceneTurntableAsset.pivot.image {
            image
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: frame.width, height: frame.height)
                .position(x: frame.midX, y: frame.midY)
                .shadow(color: .black.opacity(0.24), radius: 2, x: 2, y: 3)
        } else {
            Circle()
                .fill(Color(white: 0.13))
                .frame(width: layout.size.width * 0.6, height: layout.size.width * 0.6)
                .position(pivotPoint)
        }
    }

    @ViewBuilder
    private func rotatingArm(
        layout: DesktopSceneMaterialTonearmLayout,
        pivotPoint: CGPoint
    ) -> some View {
        if let image = DesktopSceneTurntableAsset.tonearm.image {
            image
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(
                    width: layout.rotatingAssemblyFrame.width,
                    height: layout.rotatingAssemblyFrame.height
                )
                .rotationEffect(.degrees(layout.rotationDegrees(isEngaged: isEngaged)))
                .position(pivotPoint)
                .shadow(color: .black.opacity(0.28), radius: 1.5, x: 1, y: 2)
        }
    }
}
