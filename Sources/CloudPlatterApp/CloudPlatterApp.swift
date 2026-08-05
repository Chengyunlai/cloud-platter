import AppKit
import CloudPlatterCore
import Combine
import SwiftUI

@main
struct CloudPlatterApp: App {
    @StateObject private var playbackModel = PlaybackModel()

    var body: some Scene {
        MenuBarExtra("CloudPlatter", systemImage: "record.circle") {
            Text(statusText)
            Divider()
            SettingsLink {
                Text("设置…")
            }
            Button("退出 CloudPlatter") {
                NSApplication.shared.terminate(nil)
            }
        }

        Settings {
            SettingsView(nowPlayingState: playbackModel.nowPlayingState)
        }
    }

    private var statusText: String {
        switch playbackModel.nowPlayingState.status {
        case .idle:
            "等待网易云音乐播放…"
        case .playing:
            playbackModel.nowPlayingState.title ?? "正在播放"
        case .paused:
            playbackModel.nowPlayingState.title ?? "已暂停"
        case .unavailable:
            "当前系统暂不支持"
        }
    }
}

@MainActor
private final class PlaybackModel: ObservableObject {
    @Published private(set) var nowPlayingState = NowPlayingState.idle

    private var observationTask: Task<Void, Never>?

    init(source: MediaRemoteObservationSource = MediaRemoteObservationSource()) {
        observationTask = Task { [weak self] in
            for await state in source.states() {
                guard let self else {
                    return
                }
                nowPlayingState = state
            }
        }
    }

    deinit {
        observationTask?.cancel()
    }
}

private struct SettingsView: View {
    let nowPlayingState: NowPlayingState

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            artwork

            VStack(alignment: .leading, spacing: 12) {
                Label("CloudPlatter", systemImage: "record.circle")
                    .font(.title2)
                Text("技术验证阶段")
                    .foregroundStyle(.secondary)
                Text(statusText)
            }
        }
        .padding(24)
        .frame(width: 420, height: 180, alignment: .topLeading)
    }

    @ViewBuilder
    private var artwork: some View {
        Group {
            if let artworkData = nowPlayingState.artwork,
                let image = NSImage(data: artworkData)
            {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .accessibilityLabel("当前专辑封面")
            } else {
                Image(systemName: "record.circle.fill")
                    .resizable()
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("默认唱片")
            }
        }
        .frame(width: 88, height: 88)
        .clipShape(Circle())
    }

    private var statusText: String {
        switch nowPlayingState.status {
        case .unavailable:
            "当前系统暂不兼容，已使用默认唱片。"
        case .idle:
            "播放一首网易云音乐歌曲后，这里将显示当前曲目。"
        case .playing, .paused:
            nowPlayingState.title ?? "当前曲目"
        }
    }
}
