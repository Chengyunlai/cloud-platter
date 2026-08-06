import CloudPlatterCore
import Combine
import Foundation

@MainActor
final class PlaybackModel: ObservableObject {
    @Published private(set) var nowPlayingState = NowPlayingState.idle
    @Published private(set) var pendingPlaybackControl: PlaybackControlCommand?
    @Published private(set) var playbackControlFailure: PlaybackControlFailure?

    private let controller: any PlaybackControlling
    private var observationTask: Task<Void, Never>?

    init(
        source: any PlaybackObservationSource = FallbackPlaybackObservationSource(),
        controller: any PlaybackControlling = MediaRemotePlaybackController()
    ) {
        self.controller = controller
        observationTask = Task { [weak self] in
            for await state in source.states() {
                guard let self else {
                    return
                }
                nowPlayingState = state
            }
        }
    }

    var canControlPlayback: Bool {
        nowPlayingState.status == .playing || nowPlayingState.status == .paused
    }

    func performPlaybackControl(_ command: PlaybackControlCommand) async {
        guard canControlPlayback, pendingPlaybackControl == nil else {
            return
        }

        pendingPlaybackControl = command
        playbackControlFailure = nil
        let result = await controller.send(command)
        pendingPlaybackControl = nil
        if case .failed(let failure) = result {
            playbackControlFailure = failure
        }
    }

    deinit {
        observationTask?.cancel()
    }
}
