import AppKit
import CloudPlatterCore
import SwiftUI

@main
struct CloudPlatterApp: App {
  private let nowPlayingState = NowPlayingState.idle

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
      SettingsView(nowPlayingState: nowPlayingState)
    }
  }

  private var statusText: String {
    switch nowPlayingState.status {
    case .idle:
      "等待网易云音乐播放…"
    case .playing:
      nowPlayingState.title ?? "正在播放"
    case .paused:
      nowPlayingState.title ?? "已暂停"
    case .unavailable:
      "当前系统暂不支持"
    }
  }
}

private struct SettingsView: View {
  let nowPlayingState: NowPlayingState

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Label("CloudPlatter", systemImage: "record.circle")
        .font(.title2)
      Text("技术验证阶段")
        .foregroundStyle(.secondary)
      Text(nowPlayingState.title ?? "播放一首网易云音乐歌曲后，这里将显示当前曲目。")
    }
    .padding(24)
    .frame(width: 420, height: 180, alignment: .topLeading)
  }
}
