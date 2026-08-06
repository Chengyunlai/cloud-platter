import AppKit
import SwiftUI

/// 优先呈现可随应用分发的高分辨率木纹，并在资源异常时保留稳定的降级背景。
struct DesktopSceneWalnutBackground: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let image = DesktopSceneWalnutTexture.image {
                    image
                        .resizable()
                        .interpolation(.high)
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                } else {
                    DesktopSceneWalnutFallback()
                }

                Color(red: 0.08, green: 0.025, blue: 0.012)
                    .opacity(0.24)

                RadialGradient(
                    colors: [
                        Color(red: 1, green: 0.76, blue: 0.5).opacity(0.18),
                        .clear,
                    ],
                    center: UnitPoint(x: 0.72, y: 0.04),
                    startRadius: 0,
                    endRadius: max(proxy.size.width, proxy.size.height) * 0.72
                )

                RadialGradient(
                    colors: [.clear, .black.opacity(0.38)],
                    center: .center,
                    startRadius: min(proxy.size.width, proxy.size.height) * 0.24,
                    endRadius: max(proxy.size.width, proxy.size.height) * 0.76
                )

                LinearGradient(
                    colors: [.white.opacity(0.035), .clear, .black.opacity(0.18)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}

/// 集中处理 SwiftPM 开发构建与独立 App 包中的资源位置差异。
enum DesktopSceneWalnutTexture {
    static let resourceName = "walnut-desktop-4k"

    static var image: Image? {
        guard let image = nsImage else {
            return nil
        }
        return Image(nsImage: image)
    }

    static var moduleResourceURL: URL? {
        // 独立 App 缺少资源时不能触发 SwiftPM 自动访问器中的 fatalError。
        guard Bundle.main.bundleURL.pathExtension != "app" else {
            return nil
        }
        return Bundle.module.url(forResource: resourceName, withExtension: "jpg")
    }

    private static let nsImage: NSImage? = {
        let packagedURL = Bundle.main.url(
            forResource: resourceName,
            withExtension: "jpg",
            subdirectory: "Visuals"
        )
        guard let url = packagedURL ?? moduleResourceURL else {
            return nil
        }
        return NSImage(contentsOf: url)
    }()
}

/// 仅在木纹文件缺失或损坏时使用，避免桌面窗口出现空白。
private struct DesktopSceneWalnutFallback: View {
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

        }
    }
}
