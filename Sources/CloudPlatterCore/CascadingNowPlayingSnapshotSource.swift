import Foundation

/// 按顺序查询多个一次性播放状态源，并优先返回第一个可展示的网易云状态。
///
/// 单个来源空闲或不可用时会继续尝试下一来源；所有来源都失败时，空闲结果优先于不可用，
/// 避免把“当前没有媒体”错误展示成适配器故障。
struct CascadingNowPlayingSnapshotSource: NowPlayingSnapshotFetching, Sendable {
    let sources: [any NowPlayingSnapshotFetching]

    func fetch() async -> NowPlayingState {
        var didObserveIdleState = false

        for source in sources {
            let state = await source.fetch()
            switch state.status {
            case .playing, .paused:
                return state
            case .idle:
                didObserveIdleState = true
            case .unavailable:
                continue
            }
        }

        return didObserveIdleState ? .idle : NowPlayingState(status: .unavailable)
    }
}
