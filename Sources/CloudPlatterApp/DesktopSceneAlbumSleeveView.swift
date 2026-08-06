import AppKit
import SwiftUI

/// 呈现桌面左侧的实体专辑封套，并限制低分辨率封面的放大倍数。
struct DesktopSceneAlbumSleeveView: View {
    let content: DesktopSceneAlbumSleeveContent

    @Environment(\.displayScale) private var displayScale

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let inset = size.width * 0.065
            let layout = DesktopSceneAlbumSleeveLayout(
                sleeveSize: size,
                artworkPixelSize: artworkPixelSize,
                displayScale: displayScale
            )

            ZStack {
                paperSurface

                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top, spacing: size.width * 0.055) {
                        artworkPlate(layout: layout)

                        recordDetails(size: size, height: layout.artworkPlateSide)
                    }

                    Spacer(minLength: size.height * 0.035)

                    Text(content.titleText)
                        .font(
                            .system(
                                size: min(42, max(22, size.width * 0.065)),
                                weight: .semibold,
                                design: .serif
                            )
                        )
                        .tracking(-0.4)
                        .foregroundStyle(Color(red: 0.13, green: 0.12, blue: 0.1))
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("CloudPlatter")
                            .font(.system(size: max(8, size.width * 0.018), weight: .semibold))

                        Spacer()

                        Text("33⅓ RPM")
                            .font(.system(size: max(7, size.width * 0.016), weight: .medium))
                    }
                    .tracking(0.7)
                    .foregroundStyle(Color.black.opacity(0.62))
                    .padding(.top, size.height * 0.025)
                }
                .padding(inset)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
        .compositingGroup()
        .shadow(color: .black.opacity(0.38), radius: 8, y: 10)
        .accessibilityLabel(
            content.artworkData == nil ? "CloudPlatter 默认封套" : "当前专辑封套")
    }

    private func artworkPlate(layout: DesktopSceneAlbumSleeveLayout) -> some View {
        ZStack {
            Color(red: 0.12, green: 0.13, blue: 0.13)

            Circle()
                .stroke(Color.white.opacity(0.045), lineWidth: 1)
                .frame(
                    width: layout.artworkPlateSide * 0.74,
                    height: layout.artworkPlateSide * 0.74
                )

            DesktopSceneArtworkSurface(artworkData: content.artworkData)
                .frame(width: layout.artworkSide, height: layout.artworkSide)
                .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.28), lineWidth: 1)
                }
        }
        .frame(width: layout.artworkPlateSide, height: layout.artworkPlateSide)
        .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
    }

    private func recordDetails(size: CGSize, height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: max(7, size.height * 0.014)) {
            Text(content.albumText)
                .font(.system(size: min(16, max(10, size.width * 0.028)), weight: .semibold))
                .foregroundStyle(Color(red: 0.17, green: 0.15, blue: 0.12))
                .lineLimit(3)
                .minimumScaleFactor(0.75)

            Rectangle()
                .fill(Color.black.opacity(0.24))
                .frame(height: 1)

            Text(content.artistText)
                .font(.system(size: min(14, max(9, size.width * 0.024))))
                .foregroundStyle(Color.black.opacity(0.68))
                .lineLimit(3)
                .minimumScaleFactor(0.75)

            Spacer(minLength: 0)

            Text("桌面唱片 · 随乐呈现")
                .font(.system(size: max(7, size.width * 0.016), weight: .medium))
                .foregroundStyle(Color.black.opacity(0.52))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, minHeight: height, maxHeight: height, alignment: .topLeading)
    }

    private var paperSurface: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.9, green: 0.87, blue: 0.79),
                    Color(red: 0.79, green: 0.75, blue: 0.66),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Canvas { context, size in
                for index in 0..<11 {
                    let y = size.height * (CGFloat(index) + 0.7) / 11
                    var path = Path()
                    path.move(to: CGPoint(x: size.width * 0.03, y: y))
                    path.addLine(to: CGPoint(x: size.width * 0.97, y: y + 0.5))
                    context.stroke(path, with: .color(.white.opacity(0.055)), lineWidth: 0.6)
                }
            }
        }
    }

    private var artworkPixelSize: CGSize? {
        guard let artworkData = content.artworkData,
            let bitmap = NSBitmapImageRep(data: artworkData)
        else {
            return nil
        }
        return CGSize(width: bitmap.pixelsWide, height: bitmap.pixelsHigh)
    }
}
