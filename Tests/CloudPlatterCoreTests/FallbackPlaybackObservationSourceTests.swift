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

    private func makeSource(
        primaryStates: [NowPlayingState],
        fallbackStates: [NowPlayingState]
    ) -> FallbackPlaybackObservationSource {
        FallbackPlaybackObservationSource(
            primary: ImmediatePlaybackObservationSource(states: primaryStates),
            fallback: SequenceSnapshotFetcher(states: fallbackStates),
            activePollInterval: .milliseconds(1),
            idlePollInterval: .milliseconds(1),
            failurePollInterval: .milliseconds(1)
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
