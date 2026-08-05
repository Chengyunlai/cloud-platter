import Foundation
import SwiftUI

/// 呈现桌面左侧的实体专辑封套。
struct DesktopSceneAlbumSleeveView: View {
    let artworkData: Data?

    var body: some View {
        GeometryReader { proxy in
            let inset = proxy.size.width * 0.055

            ZStack(alignment: .bottomTrailing) {
                Color(red: 0.85, green: 0.81, blue: 0.72)

                DesktopSceneArtworkSurface(artworkData: artworkData)
                    .padding(.top, inset)
                    .padding(.horizontal, inset)
                    .padding(.bottom, inset * 1.35)

                Text("CLOUDPLATTER · 33⅓ RPM")
                    .font(.system(size: max(6, proxy.size.width * 0.022), weight: .medium))
                    .tracking(1.1)
                    .foregroundStyle(Color.black.opacity(0.58))
                    .padding(.trailing, inset)
                    .padding(.bottom, inset * 0.38)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
        .shadow(color: .black.opacity(0.38), radius: 8, y: 10)
        .accessibilityLabel(artworkData == nil ? "CloudPlatter 默认封套" : "当前专辑封套")
    }
}
