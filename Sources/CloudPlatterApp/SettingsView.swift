import CloudPlatterCore
import SwiftUI

struct SettingsView: View {
    @Environment(\.scenePhase) private var scenePhase

    let nowPlayingState: NowPlayingState
    @ObservedObject var launchAtLoginModel: LaunchAtLoginModel

    private var presentation: NowPlayingPresentation {
        NowPlayingPresentation(state: nowPlayingState)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            header
            playbackCard
            launchAtLoginCard
            desktopSceneNote
            privacyNote
        }
        .padding(26)
        .frame(width: 520, height: 500, alignment: .topLeading)
        .onAppear {
            launchAtLoginModel.refresh()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            launchAtLoginModel.refresh()
        }
    }

    private var launchAtLoginCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(
                "登录时启动",
                isOn: Binding(
                    get: { launchAtLoginModel.isEnabled },
                    set: { launchAtLoginModel.setEnabled($0) }
                )
            )
            .disabled(!launchAtLoginModel.canChangeRegistration)

            Text(launchAtLoginModel.statusMessage)
                .font(.caption)
                .foregroundStyle(.secondary)

            if launchAtLoginModel.status == .requiresApproval {
                Button("打开登录项设置") {
                    launchAtLoginModel.openSystemSettings()
                }
                .buttonStyle(.link)
            }

            if let feedbackMessage = launchAtLoginModel.feedbackMessage {
                Label(feedbackMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(16)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 14))
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

    private var desktopSceneNote: some View {
        Label(
            "全屏场景会铺满每块显示器，并保持点击穿透；桌面图标和其他应用仍可正常使用。",
            systemImage: "display.2"
        )
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private var privacyNote: some View {
        Label(
            "播放信息和三种基础控制都留在这台 Mac，不需要再次登录，也不会上传收听记录。",
            systemImage: "lock.shield"
        )
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}
