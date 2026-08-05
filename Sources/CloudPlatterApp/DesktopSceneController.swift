import AppKit
import SwiftUI

@MainActor
final class DesktopSceneController: ObservableObject {
    private let panel: DesktopScenePanel

    init(playbackModel: PlaybackModel) {
        let contentSize = NSSize(width: 400, height: 330)
        panel = DesktopScenePanel(
            contentRect: NSRect(origin: .zero, size: contentSize)
        )
        panel.contentView = NSHostingView(
            rootView: DesktopSceneView(playbackModel: playbackModel)
        )
        positionOnDesktop()
    }

    func show() {
        guard !panel.isVisible else {
            return
        }
        positionOnDesktop()
        panel.orderFrontRegardless()
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
}
