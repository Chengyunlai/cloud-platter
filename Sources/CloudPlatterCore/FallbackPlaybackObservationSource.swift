import Foundation

/// 合并默认事件流与按需 JXA 查询，避免瞬时空快照清空正在播放界面。
///
/// 默认事件流正常时不会启动 JXA。主流进入空闲或不可用状态后才开始轮询；主流恢复后立即停用
/// 备用查询。两条路径都失败时输出主流的安全降级状态，不抛出底层错误或原始媒体字段。
public struct FallbackPlaybackObservationSource: PlaybackObservationSource, Sendable {
    private let primary: any PlaybackObservationSource
    private let fallback: any NowPlayingSnapshotFetching
    private let pollingPolicy: FallbackPollingPolicy

    public init() {
        self.init(
            primary: MediaRemoteObservationSource(),
            fallback: JXANowPlayingSnapshotSource(),
            pollingPolicy: .standard
        )
    }

    init(
        primary: any PlaybackObservationSource,
        fallback: any NowPlayingSnapshotFetching,
        pollingPolicy: FallbackPollingPolicy
    ) {
        self.primary = primary
        self.fallback = fallback
        self.pollingPolicy = pollingPolicy
    }

    public func states() -> AsyncStream<NowPlayingState> {
        AsyncStream { continuation in
            let selector = FallbackPlaybackStateSelector(
                continuation: continuation,
                pollingPolicy: pollingPolicy
            )
            let primaryTask = Task {
                for await state in primary.states() {
                    await selector.receivePrimary(state)
                }
                await selector.primaryDidFinish()
            }
            let fallbackTask = Task {
                while !Task.isCancelled {
                    guard await selector.waitUntilFallbackIsNeeded() else {
                        break
                    }
                    guard !Task.isCancelled else {
                        break
                    }

                    guard let state = await selector.fetchFallback(using: fallback) else {
                        continue
                    }
                    let delay = await selector.receiveFallback(state)
                    do {
                        try await Task.sleep(for: delay)
                    } catch {
                        break
                    }
                }
            }

            continuation.onTermination = { _ in
                primaryTask.cancel()
                fallbackTask.cancel()
                Task {
                    await selector.stop()
                }
            }
        }
    }
}

/// 集中定义备用查询在不同结果下的间隔，避免各调用点分别解释轮询策略。
struct FallbackPollingPolicy: Sendable {
    let activeInterval: Duration
    let idleInterval: Duration
    let failureInterval: Duration

    static let standard = FallbackPollingPolicy(
        activeInterval: .seconds(1),
        idleInterval: .seconds(2),
        failureInterval: .seconds(4)
    )
}

private actor FallbackPlaybackStateSelector {
    private let continuation: AsyncStream<NowPlayingState>.Continuation
    private let pollingPolicy: FallbackPollingPolicy

    private var fallbackWaiters: [CheckedContinuation<Bool, Never>] = []
    private var fallbackFetchTask: Task<NowPlayingState, Never>?
    private var fallbackFetchGeneration = 0
    private var isFallbackNeeded = false
    private var isStopped = false
    private var lastYieldedState: NowPlayingState?
    private var primaryFallbackState = NowPlayingState.idle

    init(
        continuation: AsyncStream<NowPlayingState>.Continuation,
        pollingPolicy: FallbackPollingPolicy
    ) {
        self.continuation = continuation
        self.pollingPolicy = pollingPolicy
    }

    func receivePrimary(_ state: NowPlayingState) {
        guard !isStopped else {
            return
        }

        switch state.status {
        case .playing, .paused:
            isFallbackNeeded = false
            cancelFallbackFetch()
            yieldIfChanged(state)
        case .idle, .unavailable:
            primaryFallbackState = state
            isFallbackNeeded = true
            resumeFallbackWaiters(with: true)
        }
    }

    func primaryDidFinish() {
        guard !isStopped else {
            return
        }
        primaryFallbackState = NowPlayingState(status: .unavailable)
        isFallbackNeeded = true
        resumeFallbackWaiters(with: true)
    }

    func waitUntilFallbackIsNeeded() async -> Bool {
        if isStopped {
            return false
        }
        if isFallbackNeeded {
            return true
        }
        return await withCheckedContinuation { continuation in
            fallbackWaiters.append(continuation)
        }
    }

    func fetchFallback(using fallback: any NowPlayingSnapshotFetching) async
        -> NowPlayingState?
    {
        guard !isStopped, isFallbackNeeded else {
            return nil
        }

        fallbackFetchGeneration += 1
        let generation = fallbackFetchGeneration
        let task = Task {
            await fallback.fetch()
        }
        fallbackFetchTask = task
        let state = await task.value

        if generation == fallbackFetchGeneration {
            fallbackFetchTask = nil
        }
        guard !task.isCancelled, !isStopped, isFallbackNeeded else {
            return nil
        }
        return state
    }

    func receiveFallback(_ state: NowPlayingState) -> Duration {
        guard !isStopped, isFallbackNeeded else {
            return .zero
        }

        switch state.status {
        case .playing, .paused:
            yieldIfChanged(state)
            return pollingPolicy.activeInterval
        case .idle:
            yieldIfChanged(.idle)
            return pollingPolicy.idleInterval
        case .unavailable:
            yieldIfChanged(primaryFallbackState)
            return pollingPolicy.failureInterval
        }
    }

    func stop() {
        guard !isStopped else {
            return
        }
        isStopped = true
        cancelFallbackFetch()
        resumeFallbackWaiters(with: false)
    }

    private func yieldIfChanged(_ state: NowPlayingState) {
        guard state != lastYieldedState else {
            return
        }
        lastYieldedState = state
        continuation.yield(state)
    }

    private func resumeFallbackWaiters(with value: Bool) {
        let waiters = fallbackWaiters
        fallbackWaiters.removeAll(keepingCapacity: false)
        for waiter in waiters {
            waiter.resume(returning: value)
        }
    }

    private func cancelFallbackFetch() {
        fallbackFetchGeneration += 1
        fallbackFetchTask?.cancel()
        fallbackFetchTask = nil
    }
}
