import CloudPlatterCore
import SwiftUI

struct SettingsView: View {
    @Environment(\.scenePhase) private var scenePhase

    let nowPlayingState: NowPlayingState
    @ObservedObject var launchAtLoginModel: LaunchAtLoginModel
    @ObservedObject var desktopSceneSettings: DesktopSceneSettings

    private var presentation: NowPlayingPresentation {
        NowPlayingPresentation(state: nowPlayingState)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                playbackCard
                desktopSceneCard
                launchAtLoginCard
                desktopSceneNote
                privacyNote
            }
            .padding(26)
        }
        .frame(width: 520, height: 640, alignment: .topLeading)
        .onAppear {
            launchAtLoginModel.refresh()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            launchAtLoginModel.refresh()
        }
    }

    private var desktopSceneCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(
                "显示桌面唱机",
                isOn: Binding(
                    get: { desktopSceneSettings.isSceneVisible },
                    set: { desktopSceneSettings.setSceneVisible($0) }
                )
            )

            Text("显示器")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(desktopSceneSettings.availableDisplays) { display in
                Toggle(
                    display.name,
                    isOn: Binding(
                        get: { desktopSceneSettings.isDisplayEnabled(display.id) },
                        set: { desktopSceneSettings.setDisplayEnabled($0, identifier: display.id) }
                    )
                )
            }

            Text("显示开关与屏幕选择会在重启后保留。隐藏时暂停场景动画，音乐继续播放。")
                .font(.caption)
                .foregroundStyle(.secondary)

            if !desktopSceneSettings.availableDisplays.isEmpty,
                !desktopSceneSettings.availableDisplays.contains(where: {
                    desktopSceneSettings.isDisplayEnabled($0.id)
                })
            {
                Text("未选中任何显示器；选择一个屏幕后即可显示唱机。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 14))
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
            "全屏场景会铺满选中的显示器，并保持点击穿透；桌面图标和其他应用仍可正常使用。",
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
