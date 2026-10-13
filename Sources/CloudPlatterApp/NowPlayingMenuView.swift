import AppKit
import CloudPlatterCore
import SwiftUI

struct NowPlayingMenuView: View {
    let nowPlayingState: NowPlayingState
    @ObservedObject var desktopSceneSettings: DesktopSceneSettings

    private var presentation: NowPlayingPresentation {
        NowPlayingPresentation(state: nowPlayingState)
    }

    var body: some View {
        VStack(spacing: 0) {
            playbackContent
                .padding(18)

            Divider()

            Button {
                desktopSceneSettings.toggleSceneVisibility()
            } label: {
                Label(
                    desktopSceneSettings.isSceneVisible ? "隐藏桌面唱机" : "显示桌面唱机",
                    systemImage: desktopSceneSettings.isSceneVisible ? "eye.slash" : "eye"
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)

            Divider()

            HStack(spacing: 8) {
                SettingsLink {
                    Label("打开设置", systemImage: "gearshape")
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Label("退出", systemImage: "power")
                }
                .buttonStyle(.plain)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
        .frame(width: 360)
    }

    private var playbackContent: some View {
        HStack(alignment: .top, spacing: 14) {
            ArtworkView(artworkData: nowPlayingState.artwork, size: 80)

            VStack(alignment: .leading, spacing: 7) {
                NowPlayingStatusBadge(presentation: presentation)

                Text(presentation.titleText)
                    .font(.headline)
                    .lineLimit(2)

                if presentation.showsMetadata {
                    Text(presentation.artistText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text(presentation.albumText)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                } else {
                    Text(presentation.guidanceText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
