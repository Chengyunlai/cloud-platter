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
        nowPlayingState.sourceBundleIdentifier
            == SupportedMediaSource.neteaseMusicBundleIdentifier
            && (nowPlayingState.status == .playing || nowPlayingState.status == .paused)
    }

    func performPlaybackControl(_ command: PlaybackControlCommand) async {
        guard canControlPlayback, pendingPlaybackControl == nil else {
            return
        }

        pendingPlaybackControl = command
        playbackControlFailure = nil
        let result = await sendWithinResponseDeadline(command)
        pendingPlaybackControl = nil
        if case .failed(let failure) = result {
            playbackControlFailure = failure
        }
    }

    private func sendWithinResponseDeadline(
        _ command: PlaybackControlCommand
    ) async -> PlaybackControlResult {
        let controller = self.controller
        return await withCheckedContinuation { continuation in
            let completion = PlaybackControlCompletion(continuation: continuation)
            let commandTask = Task {
                let result = await controller.send(command)
                completion.finish(result)
            }

            Task {
                do {
                    try await Task.sleep(for: PlaybackControlTiming.responseDeadline)
                } catch {
                    return
                }
                if completion.finish(.failed(.unavailable)) {
                    commandTask.cancel()
                }
            }
        }
    }

    deinit {
        observationTask?.cancel()
    }
}

/// 只允许底层结果或界面响应期限中的一方恢复等待中的控制调用。
private final class PlaybackControlCompletion: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<PlaybackControlResult, Never>?

    init(continuation: CheckedContinuation<PlaybackControlResult, Never>) {
        self.continuation = continuation
    }

    @discardableResult
    func finish(_ result: PlaybackControlResult) -> Bool {
        lock.lock()
        guard let continuation else {
            lock.unlock()
            return false
        }
        self.continuation = nil
        lock.unlock()

        continuation.resume(returning: result)
        return true
    }
}
