import SwiftUI

/// 使用程序化图层绘制胡桃木桌面，避免把固定分辨率纹理放大后变模糊。
struct DesktopSceneWalnutBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.17, green: 0.055, blue: 0.025),
                    Color(red: 0.43, green: 0.18, blue: 0.085),
                    Color(red: 0.23, green: 0.075, blue: 0.035),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [Color(red: 1, green: 0.78, blue: 0.54).opacity(0.2), .clear],
                center: UnitPoint(x: 0.76, y: 0.08),
                startRadius: 0,
                endRadius: 520
            )

            Canvas { context, size in
                for index in 0..<15 {
                    let progress = CGFloat(index) / 14
                    let y = size.height * (0.06 + progress * 0.9)
                    var path = Path()
                    path.move(to: CGPoint(x: -size.width * 0.05, y: y))
                    path.addCurve(
                        to: CGPoint(x: size.width * 1.05, y: y + size.height * 0.035),
                        control1: CGPoint(x: size.width * 0.22, y: y - size.height * 0.045),
                        control2: CGPoint(x: size.width * 0.68, y: y + size.height * 0.055)
                    )
                    context.stroke(
                        path,
                        with: .color(.white.opacity(index.isMultiple(of: 3) ? 0.04 : 0.018)),
                        lineWidth: index.isMultiple(of: 3) ? 1.2 : 0.7
                    )
                }
            }

            LinearGradient(
                colors: [.white.opacity(0.06), .clear, .black.opacity(0.24)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
