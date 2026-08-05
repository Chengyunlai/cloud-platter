import Foundation
import Testing

@testable import CloudPlatterCore

@Suite("播放状态备用通道")
struct FallbackPlaybackObservationSourceTests {
    @Test("主事件流空闲时使用 JXA 歌曲且不闪空状态")
    func fallbackReplacesEmptyPrimaryState() async {
        let fallbackState = NowPlayingState(
            sourceBundleIdentifier: "com.netease.163music",
            title: "备用歌曲",
            artist: "备用艺人",
            status: .playing
        )
        let source = makeSource(
            primaryStates: [.idle],
            fallbackStates: [fallbackState]
        )
        var states: [NowPlayingState] = []

        for await state in source.states().prefix(1) {
            states.append(state)
        }

        #expect(states == [fallbackState])
    }

    @Test("事件流卡空闲时由一次性 MediaRemote 快照恢复播放状态")
    func mediaRemoteSnapshotRecoversStalledPrimaryStream() async {
        let recoveredState = NowPlayingState(
            sourceBundleIdentifier: "com.netease.163music",
            title: "匿名歌曲",
            artist: "匿名艺人",
            status: .playing
        )
        let snapshotSource = CascadingNowPlayingSnapshotSource(
            sources: [
                SequenceSnapshotFetcher(states: [recoveredState]),
                SequenceSnapshotFetcher(states: [.idle]),
            ]
        )
        let source = makeSource(
            primary: ImmediatePlaybackObservationSource(states: [.idle]),
            fallback: snapshotSource
        )
        var states: [NowPlayingState] = []

        for await state in source.states().prefix(1) {
            states.append(state)
        }

        #expect(states == [recoveredState])
    }

    @Test("一次性 MediaRemote 快照空闲时继续使用 JXA")
    func idleMediaRemoteSnapshotFallsThroughToJXA() async {
        let jxaState = NowPlayingState(
            sourceBundleIdentifier: "com.netease.163music",
            title: "匿名节目",
            status: .paused
        )
        let snapshotSource = CascadingNowPlayingSnapshotSource(
            sources: [
                SequenceSnapshotFetcher(states: [.idle]),
                SequenceSnapshotFetcher(states: [jxaState]),
            ]
        )

        #expect(await snapshotSource.fetch() == jxaState)
    }

    @Test("JXA 轮询持续跟随切歌并去除重复状态")
    func fallbackPollingFollowsTrackChanges() async {
        let first = NowPlayingState(title: "第一首", status: .playing)
        let second = NowPlayingState(title: "第二首", status: .playing)
        let source = makeSource(
            primaryStates: [.idle],
            fallbackStates: [first, first, second]
        )
        var states: [NowPlayingState] = []

        for await state in source.states().prefix(2) {
            states.append(state)
        }

        #expect(states.map(\.title) == ["第一首", "第二首"])
    }

    @Test("两条读取路径都没有媒体时输出空闲")
    func bothIdleSourcesProduceIdle() async {
        let source = makeSource(
            primaryStates: [.idle],
            fallbackStates: [.idle]
        )
        var states: [NowPlayingState] = []

        for await state in source.states().prefix(1) {
            states.append(state)
        }

        #expect(states == [.idle])
    }

    @Test("主事件流有效时不启动 JXA")
    func activePrimaryDoesNotStartFallback() async throws {
        let primary = ManualPlaybackObservationSource()
        let fallback = SequenceSnapshotFetcher(states: [.idle])
        let source = makeSource(primary: primary, fallback: fallback)
        let activeState = NowPlayingState(title: "匿名歌曲", status: .playing)
        let stream = source.states()
        var iterator = stream.makeAsyncIterator()

        primary.send(activeState)

        #expect(await iterator.next() == activeState)
        try await Task.sleep(for: .milliseconds(20))
        #expect(fallback.invocationCount == 0)
        primary.finish()
    }

    @Test("主事件流保持存活但静默时启动备用快照")
    func silentPrimaryStartsFallbackSnapshot() async {
        let primary = ManualPlaybackObservationSource()
        let initialState = NowPlayingState(title: "匿名歌曲一", status: .playing)
        let recoveredState = NowPlayingState(title: "匿名歌曲二", status: .playing)
        let fallback = SequenceSnapshotFetcher(states: [recoveredState])
        let source = makeSource(
            primary: primary,
            fallback: fallback,
            pollingPolicy: FallbackPollingPolicy(
                activeInterval: .seconds(1),
                idleInterval: .seconds(1),
                failureInterval: .seconds(1),
                primarySilenceTimeout: .milliseconds(10)
            )
        )
        let statesTask = Task {
            var states: [NowPlayingState] = []
            for await state in source.states().prefix(2) {
                states.append(state)
            }
            return states
        }

        primary.send(initialState)
        let states = await statesTask.value

        #expect(states == [initialState, recoveredState])
        primary.finish()
    }

    @Test("主事件流静默且备用链路失败时不保留过期歌曲")
    func silentPrimaryWithFailedFallbackBecomesUnavailable() async {
        let primary = ManualPlaybackObservationSource()
        let initialState = NowPlayingState(title: "匿名歌曲", status: .playing)
        let fallback = SequenceSnapshotFetcher(
            states: [NowPlayingState(status: .unavailable)]
        )
        let source = makeSource(
            primary: primary,
            fallback: fallback,
            pollingPolicy: FallbackPollingPolicy(
                activeInterval: .seconds(1),
                idleInterval: .seconds(1),
                failureInterval: .seconds(1),
                primarySilenceTimeout: .milliseconds(10)
            )
        )
        let statesTask = Task {
            var states: [NowPlayingState] = []
            for await state in source.states().prefix(2) {
                states.append(state)
            }
            return states
        }

        primary.send(initialState)
        let states = await statesTask.value

        #expect(states == [initialState, NowPlayingState(status: .unavailable)])
        primary.finish()
    }

    @Test("级联快照取消后不再启动下一来源")
    func cancelledCascadeDoesNotStartNextSource() async {
        let first = CancellationRecordingSnapshotFetcher()
        let second = SequenceSnapshotFetcher(states: [.idle])
        let source = CascadingNowPlayingSnapshotSource(sources: [first, second])
        let task = Task {
            await source.fetch()
        }

        await first.waitUntilStarted()
        task.cancel()
        _ = await task.value

        #expect(second.invocationCount == 0)
    }

    @Test("主事件流恢复时取消正在执行的 JXA 查询")
    func primaryRecoveryCancelsInFlightFallback() async throws {
        let primary = ManualPlaybackObservationSource()
        let fallback = CancellationRecordingSnapshotFetcher()
        let source = makeSource(primary: primary, fallback: fallback)
        let activeState = NowPlayingState(title: "匿名歌曲", status: .playing)
        let stream = source.states()
        var iterator = stream.makeAsyncIterator()

        primary.send(.idle)
        await fallback.waitUntilStarted()
        primary.send(activeState)

        #expect(await iterator.next() == activeState)
        try await Task.sleep(for: .milliseconds(20))
        #expect(await fallback.wasCancelled)
        primary.finish()
    }

    @Test("JXA 失败后使用失败退避间隔")
    func fallbackFailureUsesFailureInterval() async {
        let primary = ManualPlaybackObservationSource()
        let fallbackState = NowPlayingState(title: "匿名歌曲", status: .playing)
        let fallback = SequenceSnapshotFetcher(
            states: [NowPlayingState(status: .unavailable), fallbackState]
        )
        let source = makeSource(
            primary: primary,
            fallback: fallback,
            pollingPolicy: FallbackPollingPolicy(
                activeInterval: .milliseconds(1),
                idleInterval: .milliseconds(1),
                failureInterval: .milliseconds(30),
                primarySilenceTimeout: .seconds(1)
            )
        )
        let clock = ContinuousClock()
        let startedAt = clock.now
        let statesTask = Task {
            var states: [NowPlayingState] = []
            for await state in source.states().prefix(2) {
                states.append(state)
            }
            return states
        }

        primary.send(.idle)
        let states = await statesTask.value

        #expect(states == [.idle, fallbackState])
        #expect(startedAt.duration(to: clock.now) >= .milliseconds(25))
        primary.finish()
    }

    private func makeSource(
        primaryStates: [NowPlayingState],
        fallbackStates: [NowPlayingState]
    ) -> FallbackPlaybackObservationSource {
        FallbackPlaybackObservationSource(
            primary: ImmediatePlaybackObservationSource(states: primaryStates),
            fallback: SequenceSnapshotFetcher(states: fallbackStates),
            pollingPolicy: FallbackPollingPolicy(
                activeInterval: .milliseconds(1),
                idleInterval: .milliseconds(1),
                failureInterval: .milliseconds(1),
                primarySilenceTimeout: .seconds(1)
            )
        )
    }

    private func makeSource(
        primary: any PlaybackObservationSource,
        fallback: any NowPlayingSnapshotFetching,
        pollingPolicy: FallbackPollingPolicy = FallbackPollingPolicy(
            activeInterval: .milliseconds(1),
            idleInterval: .milliseconds(1),
            failureInterval: .milliseconds(1),
            primarySilenceTimeout: .seconds(1)
        )
    ) -> FallbackPlaybackObservationSource {
        FallbackPlaybackObservationSource(
            primary: primary,
            fallback: fallback,
            pollingPolicy: pollingPolicy
        )
    }
}

private struct ImmediatePlaybackObservationSource: PlaybackObservationSource {
    let statesToEmit: [NowPlayingState]

    init(states: [NowPlayingState]) {
        statesToEmit = states
    }

    func states() -> AsyncStream<NowPlayingState> {
        AsyncStream { continuation in
            for state in statesToEmit {
                continuation.yield(state)
            }
            continuation.finish()
        }
    }
}

private final class SequenceSnapshotFetcher: NowPlayingSnapshotFetching,
    @unchecked Sendable
{
    private let lock = NSLock()
    private let states: [NowPlayingState]
    private var index = 0

    var invocationCount: Int {
        lock.withLock { index }
    }

    init(states: [NowPlayingState]) {
        self.states = states
    }

    func fetch() async -> NowPlayingState {
        lock.withLock {
            let state = states[min(index, states.count - 1)]
            index += 1
            return state
        }
    }
}

private final class ManualPlaybackObservationSource: PlaybackObservationSource,
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

    func finish() {
        continuation.finish()
    }
}

private actor CancellationRecordingSnapshotFetcher: NowPlayingSnapshotFetching {
    private var startedWaiters: [CheckedContinuation<Void, Never>] = []
    private var hasStarted = false
    private(set) var wasCancelled = false

    func fetch() async -> NowPlayingState {
        hasStarted = true
        let waiters = startedWaiters
        startedWaiters.removeAll(keepingCapacity: false)
        for waiter in waiters {
            waiter.resume()
        }

        do {
            try await Task.sleep(for: .seconds(1))
        } catch {
            wasCancelled = true
        }
        return NowPlayingState(status: .unavailable)
    }

    func waitUntilStarted() async {
        if hasStarted {
            return
        }
        await withCheckedContinuation { continuation in
            startedWaiters.append(continuation)
        }
    }
}
