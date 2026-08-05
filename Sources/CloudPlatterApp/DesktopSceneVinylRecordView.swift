import Foundation
import SwiftUI

/// 绘制可旋转的黑胶唱片与中央封面标签。
struct DesktopSceneVinylRecordView: View {
    let artworkData: Data?

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            Color.black,
                            Color(white: 0.15),
                            Color(white: 0.035),
                            Color(white: 0.12),
                            Color.black,
                        ],
                        center: .center
                    )
                )

            ForEach([0.62, 0.72, 0.82, 0.91], id: \.self) { scale in
                Circle()
                    .stroke(.white.opacity(0.12), lineWidth: 0.7)
                    .scaleEffect(scale)
            }

            GeometryReader { proxy in
                DesktopSceneArtworkSurface(artworkData: artworkData)
                    .frame(
                        width: proxy.size.width * 0.32,
                        height: proxy.size.width * 0.32
                    )
                    .clipShape(Circle())
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            }

            Circle()
                .fill(.black)
                .frame(width: 8, height: 8)

            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            .clear, .white.opacity(0.14), .clear, .white.opacity(0.05), .clear,
                        ],
                        center: .center
                    )
                )
                .blendMode(.screen)
        }
        .shadow(color: .black.opacity(0.42), radius: 8, y: 9)
        .accessibilityLabel(artworkData == nil ? "默认唱片" : "使用当前封面的唱片")
    }
}
