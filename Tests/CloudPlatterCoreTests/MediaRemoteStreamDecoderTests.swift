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

    @Test("未知事件类型被拒绝")
    func unknownEventTypeThrows() {
        var decoder = MediaRemoteStreamDecoder()

        #expect(throws: MediaRemoteStreamDecodingError.unsupportedEventType("notice")) {
            try decoder.decode(
                line: Data(#"{"type":"notice","diff":false,"payload":{}}"#.utf8)
            )
        }
    }
}
