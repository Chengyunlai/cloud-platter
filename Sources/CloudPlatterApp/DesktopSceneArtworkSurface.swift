import AppKit
import Foundation
import SwiftUI

/// 在内存中解码封面；数据缺失或无效时退回稳定的项目默认视觉。
struct DesktopSceneArtworkSurface: View {
    let artworkData: Data?

    @ViewBuilder
    var body: some View {
        if let artworkData,
            let image = NSImage(data: artworkData)
        {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .scaledToFill()
        } else {
            DesktopScenePlaceholderArtworkView()
        }
    }
}

private struct DesktopScenePlaceholderArtworkView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.15, blue: 0.23),
                    Color(red: 0.72, green: 0.25, blue: 0.29),
                    Color(red: 0.48, green: 0.59, blue: 0.51),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color(red: 1, green: 0.8, blue: 0.34))
                .frame(width: 54, height: 54)
                .offset(x: 42, y: -38)

            Text("夜航")
                .font(.system(size: 32, weight: .semibold, design: .serif))
                .tracking(5)
                .foregroundStyle(.white.opacity(0.94))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(28)
        }
    }
}
