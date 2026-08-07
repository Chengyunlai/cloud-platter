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
                state: NowPlayingState(
                    sourceBundleIdentifier: "com.netease.163music",
                    title: "匿名歌曲",
                    status: .playing
                )
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

    @Test("播放中点击播放按钮时发送显式暂停命令")
    func playingMediaResolvesToggleToPause() async {
        let controller = RecordingPlaybackController(result: .sent)
        let model = PlaybackModel(
            source: SingleStatePlaybackSource(
                state: NowPlayingState(
                    sourceBundleIdentifier: "com.netease.163music",
                    title: "匿名歌曲",
                    status: .playing
                )
            ),
            controller: controller
        )
        await waitUntilControllable(model)

        await model.performPlaybackControl(.togglePlayPause)

        let commands = await controller.commands
        #expect(commands == [.pause])
    }

    @Test("暂停中点击播放按钮时发送显式播放命令")
    func pausedMediaResolvesToggleToPlay() async {
        let controller = RecordingPlaybackController(result: .sent)
        let model = PlaybackModel(
            source: SingleStatePlaybackSource(
                state: NowPlayingState(
                    sourceBundleIdentifier: "com.netease.163music",
                    title: "匿名歌曲",
                    status: .paused
                )
            ),
            controller: controller
        )
        await waitUntilControllable(model)

        await model.performPlaybackControl(.togglePlayPause)

        let commands = await controller.commands
        #expect(commands == [.play])
    }

    @Test("其他播放器处于活动状态时仍禁用网易云控制")
    func unsupportedActiveMediaDoesNotEnableControls() async {
        let controller = RecordingPlaybackController(result: .sent)
        let model = PlaybackModel(
            source: SingleStatePlaybackSource(
                state: NowPlayingState(
                    sourceBundleIdentifier: "com.apple.Music",
                    title: "匿名歌曲",
                    status: .playing
                )
            ),
            controller: controller
        )
        await Task.yield()

        await model.performPlaybackControl(.previousTrack)

        let commands = await controller.commands
        #expect(!model.canControlPlayback)
        #expect(commands.isEmpty)
    }

    @Test("来源复核不匹配后保持控制禁用")
    func unsupportedControlFailureKeepsControlsDisabled() async {
        let controller = RecordingPlaybackController(
            result: .failed(.unsupportedSource)
        )
        let model = PlaybackModel(
            source: SingleStatePlaybackSource(
                state: NowPlayingState(
                    sourceBundleIdentifier: "com.netease.163music",
                    title: "匿名歌曲",
                    status: .playing
                )
            ),
            controller: controller
        )
        await waitUntilControllable(model)

        await model.performPlaybackControl(.nextTrack)

        #expect(model.playbackControlFailure == .unsupportedSource)
        #expect(!model.canControlPlayback)
    }

    @Test("来源不匹配后仅在新状态到达时重新允许控制")
    func newPlaybackStateClearsUnsupportedControlFailure() async {
        let source = ManualPlaybackSource()
        let controller = RecordingPlaybackController(
            result: .failed(.unsupportedSource)
        )
        let initialState = NowPlayingState(
            sourceBundleIdentifier: "com.netease.163music",
            title: "匿名歌曲",
            elapsed: 10,
            status: .playing
        )
        let model = PlaybackModel(source: source, controller: controller)
        source.send(initialState)
        await waitUntilControllable(model)

        await model.performPlaybackControl(.nextTrack)
        source.send(initialState)
        await Task.yield()
        #expect(!model.canControlPlayback)

        source.send(
            NowPlayingState(
                sourceBundleIdentifier: "com.netease.163music",
                title: "匿名歌曲",
                elapsed: 11,
                status: .playing
            )
        )
        for _ in 0..<100 where !model.canControlPlayback {
            await Task.yield()
        }

        #expect(model.playbackControlFailure == nil)
        #expect(model.canControlPlayback)
    }

    @Test("player-scoped 状态变化不会绕过全局来源不匹配")
    func playerScopedChangeDoesNotClearGlobalTargetMismatch() async {
        let source = ManualPlaybackSource()
        let controller = RecordingPlaybackController(
            result: .failed(.unsupportedSource),
            targetValidation: .unsupported
        )
        let model = PlaybackModel(source: source, controller: controller)
        source.send(
            NowPlayingState(
                sourceBundleIdentifier: "com.netease.163music",
                title: "匿名歌曲",
                elapsed: 10,
                status: .playing
            )
        )
        await waitUntilControllable(model)

        await model.performPlaybackControl(.nextTrack)
        source.send(
            NowPlayingState(
                sourceBundleIdentifier: "com.netease.163music",
                title: "匿名歌曲",
                elapsed: 11,
                status: .playing
            )
        )
        for _ in 0..<100 {
            if await controller.validationCount > 0 {
                break
            }
            await Task.yield()
        }

        #expect(await controller.validationCount == 1)
        #expect(model.playbackControlFailure == .unsupportedSource)
        #expect(!model.canControlPlayback)
    }

    @Test("底层控制器停顿时在界面响应期限内解除等待状态")
    func stalledControllerReleasesPendingStateWithinDeadline() async {
        let controller = StalledPlaybackController()
        let model = PlaybackModel(
            source: SingleStatePlaybackSource(
                state: NowPlayingState(
                    sourceBundleIdentifier: "com.netease.163music",
                    title: "匿名歌曲",
                    status: .playing
                )
            ),
            controller: controller
        )
        await waitUntilControllable(model)

        let operation = Task {
            await model.performPlaybackControl(.togglePlayPause)
        }
        try? await Task.sleep(for: .milliseconds(1_200))

        #expect(model.pendingPlaybackControl == nil)
        #expect(model.playbackControlFailure == .unavailable)
        operation.cancel()
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

private final class ManualPlaybackSource: PlaybackObservationSource,
    @unchecked Sendable
{
    private let stream: AsyncStream<NowPlayingState>
    private let continuation: AsyncStream<NowPlayingState>.Continuation

    init() {
        (stream, continuation) = AsyncStream.makeStream(of: NowPlayingState.self)
    }

    func states() -> AsyncStream<NowPlayingState> {
        stream
    }

    func send(_ state: NowPlayingState) {
        continuation.yield(state)
    }
}

private actor RecordingPlaybackController: PlaybackControlling {
    private(set) var commands: [PlaybackControlCommand] = []
    private(set) var validationCount = 0
    private let result: PlaybackControlResult
    private let targetValidation: PlaybackTargetValidation

    init(
        result: PlaybackControlResult,
        targetValidation: PlaybackTargetValidation = .supported
    ) {
        self.result = result
        self.targetValidation = targetValidation
    }

    func validateCurrentTarget() async -> PlaybackTargetValidation {
        validationCount += 1
        return targetValidation
    }

    func send(_ command: PlaybackControlCommand) async -> PlaybackControlResult {
        commands.append(command)
        return result
    }
}

private actor StalledPlaybackController: PlaybackControlling {
    func validateCurrentTarget() async -> PlaybackTargetValidation {
        .supported
    }

    func send(_ command: PlaybackControlCommand) async -> PlaybackControlResult {
        try? await Task.sleep(for: .seconds(3))
        return .sent
    }
}
