import CloudPlatterCore
import Testing

@testable import CloudPlatterApp

@MainActor
@Suite("桌面播放控制状态")
struct PlaybackModelTests {
    @Test("存在网易云媒体时转发用户命令并呈现脱敏失败")
    func activeMediaForwardsCommandAndPresentsFailure() async {
        let controller = RecordingPlaybackController(
            result: .failed(.commandRejected)
        )
        let model = PlaybackModel(
            source: SingleStatePlaybackSource(
                state: NowPlayingState(title: "匿名歌曲", status: .playing)
            ),
            controller: controller
        )
        await waitUntilControllable(model)

        await model.performPlaybackControl(.nextTrack)

        let commands = await controller.commands
        #expect(commands == [.nextTrack])
        #expect(model.pendingPlaybackControl == nil)
        #expect(model.playbackControlFailure == .commandRejected)
    }

    @Test("没有可展示媒体时不会发送播放命令")
    func idleMediaDoesNotForwardCommand() async {
        let controller = RecordingPlaybackController(result: .sent)
        let model = PlaybackModel(
            source: SingleStatePlaybackSource(state: .idle),
            controller: controller
        )
        await Task.yield()

        await model.performPlaybackControl(.togglePlayPause)

        let commands = await controller.commands
        #expect(commands.isEmpty)
    }

    private func waitUntilControllable(_ model: PlaybackModel) async {
        for _ in 0..<100 {
            if model.canControlPlayback {
                return
            }
            await Task.yield()
        }
    }
}

private struct SingleStatePlaybackSource: PlaybackObservationSource {
    let state: NowPlayingState

    func states() -> AsyncStream<NowPlayingState> {
        AsyncStream { continuation in
            continuation.yield(state)
            continuation.finish()
        }
    }
}

private actor RecordingPlaybackController: PlaybackControlling {
    private(set) var commands: [PlaybackControlCommand] = []
    private let result: PlaybackControlResult

    init(result: PlaybackControlResult) {
        self.result = result
    }

    func send(_ command: PlaybackControlCommand) async -> PlaybackControlResult {
        commands.append(command)
        return result
    }
}
