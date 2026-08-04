import CloudPlatterCore
import Testing

@Suite("正在播放状态")
struct NowPlayingStateTests {
  @Test("空闲状态不包含播放元数据")
  func idleStateContainsNoPlaybackMetadata() {
    let state = NowPlayingState.idle

    #expect(state.status == .idle)
    #expect(state.sourceBundleIdentifier == nil)
    #expect(state.title == nil)
    #expect(state.artwork == nil)
    #expect(state.playbackRate == 0)
  }

  @Test("播放状态保留规范化元数据")
  func playingStatePreservesNormalizedMetadata() {
    let state = NowPlayingState(
      sourceBundleIdentifier: "com.netease.163music",
      title: "测试歌曲",
      artist: "测试艺人",
      album: "测试专辑",
      duration: 240,
      elapsed: 30,
      playbackRate: 1,
      status: .playing
    )

    #expect(state.status == .playing)
    #expect(state.sourceBundleIdentifier == "com.netease.163music")
    #expect(state.title == "测试歌曲")
    #expect(state.artist == "测试艺人")
    #expect(state.album == "测试专辑")
    #expect(state.duration == 240)
    #expect(state.elapsed == 30)
    #expect(state.playbackRate == 1)
  }
}
