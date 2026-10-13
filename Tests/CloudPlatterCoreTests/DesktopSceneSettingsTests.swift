import AppKit
import CloudPlatterCore
import Foundation
import SwiftUI
import Testing

@testable import CloudPlatterApp

@MainActor
@Suite("桌面显示偏好")
struct DesktopSceneSettingsTests {
    @Test("多屏设置在固定窗口中可渲染", arguments: [0, 3])
    func settingsRenderWithDisplayOptions(_ displayCount: Int) throws {
        let suite = "CloudPlatterRenderTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = DesktopSceneSettings(defaults: defaults)
        settings.updateAvailableDisplays(
            (0..<displayCount).map {
                DesktopSceneDisplay(id: "screen-\($0)", name: "匿名显示器 \($0 + 1)")
            }
        )
        let view = NSHostingView(
            rootView: SettingsView(
                nowPlayingState: NowPlayingState(title: "匿名测试曲目", status: .paused),
                launchAtLoginModel: LaunchAtLoginModel(
                    bundleURL: URL(fileURLWithPath: "/tmp/CloudPlatter.app")
                ),
                desktopSceneSettings: settings
            )
            .environment(\.colorScheme, .light)
            .background(Color(nsColor: .windowBackgroundColor))
        )
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 640),
            styleMask: [.borderless], backing: .buffered, defer: false
        )
        window.appearance = NSAppearance(named: .aqua)
        window.contentView = view
        view.layoutSubtreeIfNeeded()
        let bitmap = try #require(view.bitmapImageRepForCachingDisplay(in: view.bounds))
        view.cacheDisplay(in: view.bounds, to: bitmap)
        #expect(view.bounds.size == CGSize(width: 520, height: 640))
        #expect(bitmap.pixelsWide >= 520 && bitmap.pixelsHigh >= 640)

        // 仅在维护者显式指定目录时导出匿名界面；普通测试不保存任何截图。
        if let directory = ProcessInfo.processInfo.environment["CLOUDPLATTER_REVIEW_OUTPUT"] {
            let destination = URL(fileURLWithPath: directory, isDirectory: true)
            try FileManager.default.createDirectory(
                at: destination, withIntermediateDirectories: true)
            let data = try #require(bitmap.representation(using: .png, properties: [:]))
            try data.write(
                to: destination.appendingPathComponent("settings-\(displayCount)-displays.png"))
        }
    }

    @Test("新安装默认在所有屏幕显示")
    func defaultsShowEveryDisplay() {
        withDefaults { defaults in
            let settings = DesktopSceneSettings(defaults: defaults)
            #expect(settings.isSceneVisible)
            #expect(settings.shouldShowScene(on: "screen-a"))
            #expect(settings.shouldShowScene(on: "new-screen"))
        }
    }

    @Test("隐藏与屏幕选择在重启后保留")
    func visibilityAndSelectionPersist() {
        withDefaults { defaults in
            let settings = DesktopSceneSettings(defaults: defaults)
            settings.setDisplayEnabled(false, identifier: "screen-b")
            settings.setSceneVisible(false)

            let restored = DesktopSceneSettings(defaults: defaults)
            #expect(!restored.isSceneVisible)
            #expect(!restored.shouldShowScene(on: "screen-a"))
            restored.toggleSceneVisibility()
            #expect(restored.shouldShowScene(on: "screen-a"))
            #expect(!restored.shouldShowScene(on: "screen-b"))
        }
    }

    @Test("显示器移除和重接不丢失禁用选择")
    func disconnectedDisplayKeepsSelection() {
        withDefaults { defaults in
            let settings = DesktopSceneSettings(defaults: defaults)
            let first = DesktopSceneDisplay(id: "screen-a", name: "匿名屏幕 A")
            let second = DesktopSceneDisplay(id: "screen-b", name: "匿名屏幕 B")
            settings.updateAvailableDisplays([first, second])
            settings.setDisplayEnabled(false, identifier: second.id)
            settings.updateAvailableDisplays([first])
            settings.updateAvailableDisplays([second, first])

            #expect(settings.availableDisplays == [second, first])
            #expect(!settings.shouldShowScene(on: second.id))
            #expect(settings.shouldShowScene(on: first.id))
        }
    }

    @Test("所有屏幕关闭后仍可逐个恢复")
    func emptySelectionCanBeRestored() {
        withDefaults { defaults in
            let settings = DesktopSceneSettings(defaults: defaults)
            settings.setDisplayEnabled(false, identifier: "screen-a")
            settings.setDisplayEnabled(false, identifier: "screen-b")
            #expect(!settings.shouldShowScene(on: "screen-a"))
            #expect(!settings.shouldShowScene(on: "screen-b"))

            settings.setDisplayEnabled(true, identifier: "screen-b")
            #expect(settings.shouldShowScene(on: "screen-b"))
            #expect(!settings.shouldShowScene(on: "screen-a"))
        }
    }

    private func withDefaults(_ body: (UserDefaults) -> Void) {
        let suite = "CloudPlatterTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            Issue.record("无法创建隔离的偏好存储")
            return
        }
        defer { defaults.removePersistentDomain(forName: suite) }
        body(defaults)
    }
}
