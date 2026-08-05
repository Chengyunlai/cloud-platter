import Foundation

/// 合并默认事件流与按需 JXA 查询，避免瞬时空快照清空正在播放界面。
///
/// 默认事件流正常时不会启动 JXA。主流进入空闲或不可用状态后才开始轮询；主流恢复后立即停用
/// 备用查询。两条路径都失败时输出主流的安全降级状态，不抛出底层错误或原始媒体字段。
public struct FallbackPlaybackObservationSource: PlaybackObservationSource, Sendable {
    private let primary: any PlaybackObservationSource
    private let fallback: any NowPlayingSnapshotFetching
    private let activePollInterval: Duration
    private let idlePollInterval: Duration
    private let failurePollInterval: Duration

    public init() {
        self.init(
            primary: MediaRemoteObservationSource(),
            fallback: JXANowPlayingSnapshotSource(),
            activePollInterval: .seconds(1),
            idlePollInterval: .seconds(2),
            failurePollInterval: .seconds(4)
        )
    }

    init(
        primary: any PlaybackObservationSource,
        fallback: any NowPlayingSnapshotFetching,
        activePollInterval: Duration,
        idlePollInterval: Duration,
        failurePollInterval: Duration
    ) {
        self.primary = primary
        self.fallback = fallback
        self.activePollInterval = activePollInterval
        self.idlePollInterval = idlePollInterval
        self.failurePollInterval = failurePollInterval
    }

    public func states() -> AsyncStream<NowPlayingState> {
        AsyncStream { continuation in
            let selector = FallbackPlaybackStateSelector(
                continuation: continuation,
                activePollInterval: activePollInterval,
                idlePollInterval: idlePollInterval,
                failurePollInterval: failurePollInterval
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

                    let state = await fallback.fetch()
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

private actor FallbackPlaybackStateSelector {
    private let continuation: AsyncStream<NowPlayingState>.Continuation
    private let activePollInterval: Duration
    private let idlePollInterval: Duration
    private let failurePollInterval: Duration

    private var fallbackWaiters: [CheckedContinuation<Bool, Never>] = []
    private var isFallbackNeeded = false
    private var isStopped = false
    private var lastYieldedState: NowPlayingState?
    private var primaryFallbackState = NowPlayingState.idle

    init(
        continuation: AsyncStream<NowPlayingState>.Continuation,
        activePollInterval: Duration,
        idlePollInterval: Duration,
        failurePollInterval: Duration
    ) {
        self.continuation = continuation
        self.activePollInterval = activePollInterval
        self.idlePollInterval = idlePollInterval
        self.failurePollInterval = failurePollInterval
    }

    func receivePrimary(_ state: NowPlayingState) {
        guard !isStopped else {
            return
        }

        switch state.status {
        case .playing, .paused:
            isFallbackNeeded = false
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

    func receiveFallback(_ state: NowPlayingState) -> Duration {
        guard !isStopped, isFallbackNeeded else {
            return .zero
        }

        switch state.status {
        case .playing, .paused:
            yieldIfChanged(state)
            return activePollInterval
        case .idle:
            yieldIfChanged(.idle)
            return idlePollInterval
        case .unavailable:
            yieldIfChanged(primaryFallbackState)
            return failurePollInterval
        }
    }

    func stop() {
        guard !isStopped else {
            return
        }
        isStopped = true
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
}
