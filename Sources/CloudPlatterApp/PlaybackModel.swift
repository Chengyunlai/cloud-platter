import CloudPlatterCore
import Combine
import Foundation

@MainActor
final class PlaybackModel: ObservableObject {
    @Published private(set) var nowPlayingState = NowPlayingState.idle

    private var observationTask: Task<Void, Never>?

    init(source: any PlaybackObservationSource = MediaRemoteObservationSource()) {
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
