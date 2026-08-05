import AppKit
import SwiftUI

@MainActor
final class DesktopSceneController: NSObject, ObservableObject, NSWindowDelegate {
    private let playbackModel: PlaybackModel
    private let activity = DesktopSceneActivity()
    private var panels: [CGDirectDisplayID: DesktopScenePanel] = [:]
    private var isShowing = false

    init(playbackModel: PlaybackModel) {
        self.playbackModel = playbackModel
        super.init()

        observeSessionActivity()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    func show() {
        isShowing = true
        synchronizePanels()
        for panel in panels.values where !panel.isVisible {
            panel.orderFrontRegardless()
        }
        updateWindowVisibility()
    }

    func windowDidChangeOcclusionState(_ notification: Notification) {
        updateWindowVisibility()
    }

    private func synchronizePanels() {
        let screens = NSScreen.screens.compactMap { screen -> (CGDirectDisplayID, NSScreen)? in
            guard
                let number = screen.deviceDescription[
                    NSDeviceDescriptionKey("NSScreenNumber")
                ] as? NSNumber
            else {
                return nil
            }
            return (number.uint32Value, screen)
        }
        let activeScreenIdentifiers = Set(screens.map { identifier, _ in identifier })

        for identifier in Array(panels.keys) where !activeScreenIdentifiers.contains(identifier) {
            panels.removeValue(forKey: identifier)?.close()
        }

        for (identifier, screen) in screens {
            let panel = panels[identifier] ?? makePanel(frame: screen.frame)
            panel.setFrame(screen.frame, display: panel.isVisible)
            panels[identifier] = panel
            if isShowing, !panel.isVisible {
                panel.orderFrontRegardless()
            }
        }
        updateWindowVisibility()
    }

    private func makePanel(frame: NSRect) -> DesktopScenePanel {
        let panel = DesktopScenePanel(contentRect: frame)
        panel.delegate = self
        panel.contentView = NSHostingView(
            rootView: DesktopSceneStateBridge(
                playbackModel: playbackModel,
                activity: activity
            )
        )
        return panel
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
        activity.isWindowVisible = panels.values.contains {
            $0.isVisible && $0.occlusionState.contains(.visible)
        }
    }

    @objc private func sessionDidBecomeInactive() {
        activity.isSessionActive = false
    }

    @objc private func sessionDidBecomeActive() {
        activity.isSessionActive = true
        synchronizePanels()
        updateWindowVisibility()
    }

    @objc private func screenParametersDidChange() {
        synchronizePanels()
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
