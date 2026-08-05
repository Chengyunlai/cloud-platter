import CloudPlatterCore
import SwiftUI

struct SettingsView: View {
    let nowPlayingState: NowPlayingState

    private var presentation: NowPlayingPresentation {
        NowPlayingPresentation(state: nowPlayingState)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            header
            playbackCard
            privacyNote
        }
        .padding(26)
        .frame(width: 520, height: 320, alignment: .topLeading)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "record.circle")
                .font(.title2)
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 2) {
                Text("CloudPlatter")
                    .font(.title2.weight(.semibold))
                Text("让正在播放的音乐，在桌面上被看见。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var playbackCard: some View {
        HStack(alignment: .top, spacing: 20) {
            ArtworkView(artworkData: nowPlayingState.artwork, size: 112)

            VStack(alignment: .leading, spacing: 8) {
                NowPlayingStatusBadge(presentation: presentation)

                Text(presentation.titleText)
                    .font(.title3.weight(.semibold))
                    .lineLimit(2)

                if presentation.showsMetadata {
                    Label(presentation.artistText, systemImage: "person.fill")
                    Label(presentation.albumText, systemImage: "square.stack.fill")
                }

                Text(presentation.guidanceText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .background(.quaternary.opacity(0.55), in: RoundedRectangle(cornerRadius: 16))
    }

    private var privacyNote: some View {
        Label(
            "只读取这台 Mac 上的播放信息，不需要再次登录，也不会上传收听记录。",
            systemImage: "lock.shield"
        )
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}
