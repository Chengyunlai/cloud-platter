import Foundation

/// 合并默认事件流、一次性 MediaRemote 快照与按需 JXA 查询，避免事件流停更后界面失去播放状态。
///
/// 主流进入空闲、不可用或超过静默阈值后才开始备用轮询；主流恢复后立即停用备用查询。
/// 三条路径都失败时输出主流的安全降级状态，不抛出底层错误或原始媒体字段。
public struct FallbackPlaybackObservationSource: PlaybackObservationSource, Sendable {
    private let primary: any PlaybackObservationSource
    private let fallback: any NowPlayingSnapshotFetching
    private let pollingPolicy: FallbackPollingPolicy

    public init() {
        self.init(
            primary: MediaRemoteObservationSource(),
            fallback: CascadingNowPlayingSnapshotSource(
                sources: [
                    MediaRemoteNowPlayingSnapshotSource(),
                    JXANowPlayingSnapshotSource(),
                ]
            ),
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
            let primaryWatchdogTask = Task {
                while !Task.isCancelled {
                    do {
                        try await Task.sleep(for: pollingPolicy.primarySilenceTimeout)
                    } catch {
                        break
                    }
                    await selector.detectPrimarySilence()
                }
            }

            continuation.onTermination = { _ in
                primaryTask.cancel()
                fallbackTask.cancel()
                primaryWatchdogTask.cancel()
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
    let primarySilenceTimeout: Duration

    static let standard = FallbackPollingPolicy(
        activeInterval: .seconds(1),
        idleInterval: .seconds(2),
        failureInterval: .seconds(4),
        primarySilenceTimeout: .seconds(4)
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
    private var lastPrimaryActivityAt = ContinuousClock.now

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

        lastPrimaryActivityAt = ContinuousClock.now
        primaryFallbackState = state
        switch state.status {
        case .playing, .paused:
            isFallbackNeeded = false
            cancelFallbackFetch()
            yieldIfChanged(state)
        case .idle, .unavailable:
            isFallbackNeeded = true
            resumeFallbackWaiters(with: true)
        }
    }

    func detectPrimarySilence() {
        guard !isStopped, !isFallbackNeeded else {
            return
        }
        let silenceDuration = lastPrimaryActivityAt.duration(to: ContinuousClock.now)
        guard silenceDuration >= pollingPolicy.primarySilenceTimeout else {
            return
        }

        primaryFallbackState = NowPlayingState(status: .unavailable)
        isFallbackNeeded = true
        resumeFallbackWaiters(with: true)
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
