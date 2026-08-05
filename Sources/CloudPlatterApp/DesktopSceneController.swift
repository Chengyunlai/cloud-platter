import AppKit
import SwiftUI

@MainActor
final class DesktopSceneController: NSObject, ObservableObject, NSWindowDelegate {
    private let panel: DesktopScenePanel
    private let activity = DesktopSceneActivity()

    init(playbackModel: PlaybackModel) {
        let contentSize = NSSize(width: 400, height: 330)
        panel = DesktopScenePanel(
            contentRect: NSRect(origin: .zero, size: contentSize)
        )
        super.init()

        panel.delegate = self
        panel.contentView = NSHostingView(
            rootView: DesktopSceneStateBridge(
                playbackModel: playbackModel,
                activity: activity
            )
        )
        observeSessionActivity()
        positionOnDesktop()
    }

    func show() {
        guard !panel.isVisible else {
            return
        }
        positionOnDesktop()
        panel.orderFrontRegardless()
        updateWindowVisibility()
    }

    func windowDidChangeOcclusionState(_ notification: Notification) {
        updateWindowVisibility()
    }

    private func positionOnDesktop() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else {
            return
        }

        let visibleFrame = screen.visibleFrame
        let origin = NSPoint(
            x: visibleFrame.minX + 28,
            y: visibleFrame.minY + 28
        )
        panel.setFrameOrigin(origin)
    }

    private func observeSessionActivity() {
        let notificationCenter = NSWorkspace.shared.notificationCenter
        let pauseNotifications = [
            NSWorkspace.sessionDidResignActiveNotification,
            NSWorkspace.screensDidSleepNotification,
        ]
        let resumeNotifications = [
            NSWorkspace.sessionDidBecomeActiveNotification,
            NSWorkspace.screensDidWakeNotification,
        ]

        for notification in pauseNotifications {
            notificationCenter.addObserver(
                self,
                selector: #selector(sessionDidBecomeInactive),
                name: notification,
                object: nil
            )
        }
        for notification in resumeNotifications {
            notificationCenter.addObserver(
                self,
                selector: #selector(sessionDidBecomeActive),
                name: notification,
                object: nil
            )
        }
    }

    private func updateWindowVisibility() {
        activity.isWindowVisible = panel.occlusionState.contains(.visible)
    }

    @objc private func sessionDidBecomeInactive() {
        activity.isSessionActive = false
    }

    @objc private func sessionDidBecomeActive() {
        activity.isSessionActive = true
        updateWindowVisibility()
    }
}

@MainActor
private final class DesktopSceneActivity: ObservableObject {
    @Published var isWindowVisible = false
    @Published var isSessionActive = true
}

private struct DesktopSceneStateBridge: View {
    @ObservedObject var playbackModel: PlaybackModel
    @ObservedObject var activity: DesktopSceneActivity

    var body: some View {
        DesktopSceneView(
            nowPlayingState: playbackModel.nowPlayingState,
            isWindowVisible: activity.isWindowVisible,
            isSessionActive: activity.isSessionActive
        )
    }
}
