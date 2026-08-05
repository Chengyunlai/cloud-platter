import CloudPlatterCore
import Foundation
import Testing

@testable import CloudPlatterApp

@Suite("正在播放界面展示")
struct NowPlayingPresentationTests {
    @Test("录制事件驱动菜单栏的播放、暂停和切歌展示")
    func recordedFixtureDrivesPrimaryDisplayStates() throws {
        let fixtureURL = try #require(
            Bundle.module.url(
                forResource: "netease-stream",
                withExtension: "ndjson",
                subdirectory: "Fixtures"
            )
        )
        let fixture = try String(contentsOf: fixtureURL, encoding: .utf8)
        var decoder = MediaRemoteStreamDecoder()
        var presentations: [NowPlayingPresentation] = []

        for line in fixture.split(whereSeparator: \.isNewline) {
            let state = try decoder.decode(line: Data(line.utf8))
            presentations.append(NowPlayingPresentation(state: state))
        }

        #expect(presentations.map(\.statusText) == ["正在播放", "已暂停", "正在播放"])
        #expect(presentations.map(\.menuBarTitle) == ["匿名歌曲一", "匿名歌曲一", "匿名歌曲二"])
        #expect(presentations.first?.artistText == "匿名艺人")
        #expect(presentations.first?.albumText == "匿名专辑")
    }

    @Test("空闲与不可用状态向用户说明不同情况")
    func idleAndUnavailableStatesHaveDistinctGuidance() {
        let idle = NowPlayingPresentation(state: .idle)
        let unavailable = NowPlayingPresentation(
            state: NowPlayingState(status: .unavailable)
        )

        #expect(idle.statusText == "等待播放")
        #expect(idle.titleText == "还没有正在播放的内容")
        #expect(idle.guidanceText.contains("网易云音乐"))
        #expect(unavailable.statusText == "暂时无法读取")
        #expect(unavailable.titleText == "无法读取播放状态")
        #expect(unavailable.guidanceText.contains("兼容"))
        #expect(idle != unavailable)
    }

    @Test("元数据不完整时仍提供稳定的用户文案")
    func missingOptionalMetadataUsesReadableFallbacks() {
        let presentation = NowPlayingPresentation(
            state: NowPlayingState(title: "匿名歌曲", status: .playing)
        )

        #expect(presentation.titleText == "匿名歌曲")
        #expect(presentation.artistText == "未知艺人")
        #expect(presentation.albumText == "未知专辑")
    }
}
