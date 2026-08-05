import CloudPlatterCore
import Foundation
import Testing

@Suite("MediaRemote 实时事件解码")
struct MediaRemoteStreamDecoderTests {
    @Test("全量事件转换为网易云播放状态")
    func fullEventBecomesPlayingState() throws {
        var decoder = MediaRemoteStreamDecoder()

        let state = try decoder.decode(
            line: Data(
                #"{"type":"data","diff":false,"payload":{"bundleIdentifier":"com.netease.163music","playing":true,"title":"测试歌曲","artist":"测试艺人","album":"测试专辑","duration":240,"elapsedTime":30,"playbackRate":1,"artworkData":"AQID"}}"#
                    .utf8
            )
        )

        #expect(state.status == .playing)
        #expect(state.sourceBundleIdentifier == "com.netease.163music")
        #expect(state.title == "测试歌曲")
        #expect(state.artist == "测试艺人")
        #expect(state.album == "测试专辑")
        #expect(state.duration == 240)
        #expect(state.elapsed == 30)
        #expect(state.playbackRate == 1)
        #expect(state.artwork == Data([1, 2, 3]))
    }

    @Test("增量事件保留未变化字段并删除空值字段")
    func diffEventMergesWithLastSnapshot() throws {
        var decoder = MediaRemoteStreamDecoder()
        _ = try decoder.decode(
            line: Data(
                #"{"type":"data","diff":false,"payload":{"bundleIdentifier":"com.netease.163music","playing":true,"title":"第一首","artist":"测试艺人","album":"旧专辑","elapsedTime":12}}"#
                    .utf8
            )
        )

        let state = try decoder.decode(
            line: Data(
                #"{"type":"data","diff":true,"payload":{"playing":false,"title":"第二首","album":null,"elapsedTime":19}}"#
                    .utf8
            )
        )

        #expect(state.status == .paused)
        #expect(state.title == "第二首")
        #expect(state.artist == "测试艺人")
        #expect(state.album == nil)
        #expect(state.elapsed == 19)
        #expect(state.playbackRate == 0)
    }

    @Test("其他播放器不会污染当前状态")
    func unsupportedSourceBecomesIdle() throws {
        var decoder = MediaRemoteStreamDecoder()

        let state = try decoder.decode(
            line: Data(
                #"{"type":"data","diff":false,"payload":{"bundleIdentifier":"com.apple.Music","playing":true,"title":"其他歌曲"}}"#
                    .utf8
            )
        )

        #expect(state == .idle)
    }

    @Test("来源切换到其他播放器时清空网易云状态")
    func sourceSwitchClearsNeteaseState() throws {
        var decoder = MediaRemoteStreamDecoder()
        _ = try decoder.decode(
            line: Data(
                #"{"type":"data","diff":false,"payload":{"bundleIdentifier":"com.netease.163music","playing":true,"title":"网易云歌曲"}}"#
                    .utf8
            )
        )

        let state = try decoder.decode(
            line: Data(
                #"{"type":"data","diff":false,"payload":{"bundleIdentifier":"com.apple.Music","playing":true,"title":"其他歌曲"}}"#
                    .utf8
            )
        )

        #expect(state == .idle)
    }

    @Test("空负载表示系统当前没有媒体")
    func emptyPayloadBecomesIdle() throws {
        var decoder = MediaRemoteStreamDecoder()

        let state = try decoder.decode(
            line: Data(#"{"type":"data","diff":false,"payload":{}}"#.utf8)
        )

        #expect(state == .idle)
    }

    @Test("网易云缺少必要标题时进入不可用状态")
    func supportedSourceWithoutTitleBecomesUnavailable() throws {
        var decoder = MediaRemoteStreamDecoder()

        let state = try decoder.decode(
            line: Data(
                #"{"type":"data","diff":false,"payload":{"bundleIdentifier":"com.netease.163music","playing":true}}"#
                    .utf8
            )
        )

        #expect(state.status == .unavailable)
        #expect(state.sourceBundleIdentifier == "com.netease.163music")
    }

    @Test("必要字段类型变化时进入不可用状态")
    func invalidRequiredFieldTypeBecomesUnavailable() throws {
        var decoder = MediaRemoteStreamDecoder()

        let state = try decoder.decode(
            line: Data(
                #"{"type":"data","diff":false,"payload":{"bundleIdentifier":"com.netease.163music","playing":true,"title":42}}"#
                    .utf8
            )
        )

        #expect(state.status == .unavailable)
    }

    @Test("未知事件类型被拒绝")
    func unknownEventTypeThrows() {
        var decoder = MediaRemoteStreamDecoder()

        #expect(throws: MediaRemoteDecodingError.unsupportedEventType("notice")) {
            try decoder.decode(
                line: Data(#"{"type":"notice","diff":false,"payload":{}}"#.utf8)
            )
        }
    }

    @Test("匿名 fixture 与实时事件使用相同转换路径")
    func recordedFixtureUsesProductionDecoder() throws {
        let fixtureURL = try #require(
            Bundle.module.url(
                forResource: "netease-stream",
                withExtension: "ndjson",
                subdirectory: "Fixtures"
            )
        )
        let fixture = try String(contentsOf: fixtureURL, encoding: .utf8)
        var decoder = MediaRemoteStreamDecoder()
        var states: [NowPlayingState] = []

        for line in fixture.split(whereSeparator: \.isNewline) {
            states.append(try decoder.decode(line: Data(line.utf8)))
        }

        #expect(states.map(\.status) == [.playing, .paused, .playing])
        #expect(states.map(\.title) == ["匿名歌曲一", "匿名歌曲一", "匿名歌曲二"])
    }
}
