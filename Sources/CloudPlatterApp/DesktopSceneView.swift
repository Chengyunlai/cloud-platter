import AppKit
import SwiftUI

struct DesktopSceneView: View {
    @ObservedObject var playbackModel: PlaybackModel

    private var presentation: DesktopScenePresentation {
        DesktopScenePresentation(state: playbackModel.nowPlayingState)
    }

    var body: some View {
        VStack(spacing: 10) {
            recordScene
            metadataPill
        }
        .padding(18)
        .frame(width: 400, height: 330)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("CloudPlatter 桌面唱片")
    }

    private var recordScene: some View {
        ZStack {
            AlbumSleeveView(
                artworkData: presentation.artworkData,
                usesPlaceholder: presentation.usesPlaceholderArtwork
            )
            .frame(width: 184, height: 184)
            .offset(x: -56)

            TimelineView(
                .animation(
                    minimumInterval: 1.0 / 30.0,
                    paused: !presentation.isRecordSpinning
                )
            ) { context in
                VinylRecordView(
                    artworkData: presentation.artworkData,
                    usesPlaceholder: presentation.usesPlaceholderArtwork
                )
                .frame(width: 202, height: 202)
                .rotationEffect(rotationAngle(at: context.date))
            }
            .offset(x: 62)
        }
        .frame(height: 220)
    }

    private var metadataPill: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(presentation.isRecordSpinning ? Color.green : Color.secondary)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(presentation.titleText)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(presentation.artistText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text(presentation.statusText)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(.white.opacity(0.15))
        }
        .shadow(color: .black.opacity(0.14), radius: 10, y: 4)
    }

    private func rotationAngle(at date: Date) -> Angle {
        guard presentation.isRecordSpinning else {
            return .zero
        }
        let seconds = date.timeIntervalSinceReferenceDate
        return .degrees(seconds.truncatingRemainder(dividingBy: 20) * 18)
    }
}

private struct AlbumSleeveView: View {
    let artworkData: Data?
    let usesPlaceholder: Bool

    var body: some View {
        artwork
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(.white.opacity(0.2))
            }
            .shadow(color: .black.opacity(0.25), radius: 16, y: 8)
            .accessibilityLabel(usesPlaceholder ? "CloudPlatter 默认封面" : "当前专辑封面")
    }

    @ViewBuilder
    private var artwork: some View {
        if let artworkData,
            let image = NSImage(data: artworkData)
        {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
        } else {
            PlaceholderArtworkView()
        }
    }
}

private struct VinylRecordView: View {
    let artworkData: Data?
    let usesPlaceholder: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.black.opacity(0.92), .black, .black.opacity(0.88)],
                        center: .center,
                        startRadius: 18,
                        endRadius: 104
                    )
                )

            ForEach([0.66, 0.76, 0.86, 0.94], id: \.self) { scale in
                Circle()
                    .stroke(.white.opacity(0.08), lineWidth: 0.7)
                    .scaleEffect(scale)
            }

            centerLabel
                .frame(width: 82, height: 82)
                .clipShape(Circle())

            Circle()
                .fill(.black)
                .frame(width: 8, height: 8)

            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            .clear, .white.opacity(0.12), .clear, .white.opacity(0.06), .clear,
                        ],
                        center: .center
                    )
                )
                .blendMode(.screen)
        }
        .shadow(color: .black.opacity(0.28), radius: 14, y: 7)
        .accessibilityLabel(usesPlaceholder ? "默认唱片" : "使用当前封面的唱片")
    }

    @ViewBuilder
    private var centerLabel: some View {
        if let artworkData,
            let image = NSImage(data: artworkData)
        {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
        } else {
            PlaceholderArtworkView()
        }
    }
}

private struct PlaceholderArtworkView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.2, blue: 0.28),
                    Color(red: 0.36, green: 0.12, blue: 0.55),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .stroke(.white.opacity(0.22), lineWidth: 1)
                .padding(18)

            Text("CP")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))
        }
    }
}
