import AppKit
import Combine
import SwiftUI

@MainActor
final class DesktopSceneController: NSObject, ObservableObject, NSWindowDelegate {
    private let playbackModel: PlaybackModel
    private var panels: [CGDirectDisplayID: DesktopScenePanelEntry] = [:]
    private var isShowing = false
    private var isSessionActive = true
    private var nowPlayingStateObservation: AnyCancellable?

    init(playbackModel: PlaybackModel) {
        self.playbackModel = playbackModel
        super.init()

        observeSessionActivity()
        observeNowPlayingState()
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
            guard let entry = panels.removeValue(forKey: identifier) else {
                continue
            }
            entry.scenePanel.close()
            entry.controlPanel.close()
        }

        for (identifier, screen) in screens {
            let entry = panels[identifier] ?? makePanelEntry(screenFrame: screen.frame)
            entry.scenePanel.setFrame(screen.frame, display: entry.scenePanel.isVisible)
            entry.controlPanel.setFrame(
                playbackControlFrame(screenFrame: screen.frame),
                display: entry.controlPanel.isVisible
            )
            panels[identifier] = entry
            if isShowing {
                if !entry.scenePanel.isVisible {
                    entry.scenePanel.orderFrontRegardless()
                }
                if !entry.controlPanel.isVisible {
                    entry.controlPanel.orderFrontRegardless()
                }
            }
        }
        updateWindowVisibility()
    }

    private func makePanelEntry(screenFrame: NSRect) -> DesktopScenePanelEntry {
        let activity = DesktopSceneActivity()
        activity.isSessionActive = isSessionActive
        let scenePanel = DesktopScenePanel(contentRect: screenFrame)
        scenePanel.delegate = self
        scenePanel.contentView = NSHostingView(
            rootView: DesktopSceneStateBridge(
                playbackModel: playbackModel,
                activity: activity
            )
        )
        let controlPanel = DesktopPlaybackControlPanel(
            contentRect: playbackControlFrame(screenFrame: screenFrame)
        )
        controlPanel.contentView = NSHostingView(
            rootView: DesktopPlaybackControlsView(playbackModel: playbackModel)
        )
        return DesktopScenePanelEntry(
            scenePanel: scenePanel,
            controlPanel: controlPanel,
            activity: activity
        )
    }

    private func playbackControlFrame(screenFrame: NSRect) -> NSRect {
        let presentation = DesktopScenePresentation(state: playbackModel.nowPlayingState)
        let localFrame = DesktopSceneLayout(
            canvasSize: screenFrame.size,
            subtitleText: presentation.subtitleText
        ).playbackControlsFrame
        return NSRect(
            x: screenFrame.minX + localFrame.minX,
            y: screenFrame.maxY - localFrame.maxY,
            width: localFrame.width,
            height: localFrame.height
        )
    }

    private func observeNowPlayingState() {
        nowPlayingStateObservation = playbackModel.$nowPlayingState
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.synchronizePanels()
                }
            }
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
        for entry in panels.values {
            entry.activity.isWindowVisible =
                entry.scenePanel.isVisible
                && entry.scenePanel.occlusionState.contains(.visible)
        }
    }

    @objc private func sessionDidBecomeInactive() {
        isSessionActive = false
        for entry in panels.values {
            entry.activity.isSessionActive = false
        }
    }

    @objc private func sessionDidBecomeActive() {
        isSessionActive = true
        for entry in panels.values {
            entry.activity.isSessionActive = true
        }
        synchronizePanels()
    }

    @objc private func screenParametersDidChange() {
        synchronizePanels()
    }
}

@MainActor
private struct DesktopScenePanelEntry {
    let scenePanel: DesktopScenePanel
    let controlPanel: DesktopPlaybackControlPanel
    let activity: DesktopSceneActivity
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
