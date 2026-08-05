import AppKit
import SwiftUI

struct ArtworkView: View {
    let artworkData: Data?
    let size: CGFloat

    var body: some View {
        Group {
            if let artworkData,
                let image = NSImage(data: artworkData)
            {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .accessibilityLabel("当前专辑封面")
            } else {
                ZStack {
                    LinearGradient(
                        colors: [Color.secondary.opacity(0.18), Color.secondary.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "record.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                        .padding(size * 0.2)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("默认唱片")
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: size * 0.12, style: .continuous)
                .strokeBorder(.primary.opacity(0.08))
        }
        .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
    }
}
