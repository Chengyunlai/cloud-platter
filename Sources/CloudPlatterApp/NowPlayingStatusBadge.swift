import SwiftUI

struct NowPlayingStatusBadge: View {
    let presentation: NowPlayingPresentation

    var body: some View {
        Label(presentation.statusText, systemImage: presentation.symbolName)
            .font(.caption.weight(.semibold))
            .foregroundStyle(presentation.statusTone.color)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(presentation.statusTone.color.opacity(0.12), in: Capsule())
    }
}

extension NowPlayingPresentation.StatusTone {
    fileprivate var color: Color {
        switch self {
        case .neutral:
            .secondary
        case .positive:
            .green
        case .caution:
            .orange
        case .negative:
            .red
        }
    }
}
