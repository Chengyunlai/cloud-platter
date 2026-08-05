import SwiftUI

struct NowPlayingStatusBadge: View {
    let presentation: NowPlayingPresentation

    var body: some View {
        Label(presentation.statusText, systemImage: presentation.symbolName)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(tint.opacity(0.12), in: Capsule())
    }

    private var tint: Color {
        switch presentation.kind {
        case .playing:
            .green
        case .paused:
            .orange
        case .idle:
            .secondary
        case .unavailable:
            .red
        }
    }
}
