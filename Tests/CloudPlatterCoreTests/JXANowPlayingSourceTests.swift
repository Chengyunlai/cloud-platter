import Foundation
import Testing

@testable import CloudPlatterCore

@Suite("JXA 定向播放状态源")
struct JXANowPlayingSourceTests {
    @Test("优先使用网易云定向候选项及其封面")
    func targetedCandidateBecomesNormalizedState() throws {
        let response = Data(
            #"{"complete":true,"candidates":[{"source":"global","bundleIdentifier":"com.microsoft.edgemac","playing":false,"title":"网页媒体"},{"source":"supported","bundleIdentifier":"com.netease.163music","playing":true,"title":"匿名歌曲","artist":"匿名艺人","album":"匿名专辑","duration":200,"elapsedTime":12,"playbackRate":1,"artworkData":"AQID"}]}"#
                .utf8
        )

        let state = try JXANowPlayingResponseDecoder().decode(response)

        #expect(state.status == .playing)
        #expect(state.sourceBundleIdentifier == "com.netease.163music")
        #expect(state.title == "匿名歌曲")
        #expect(state.artist == "匿名艺人")
        #expect(state.album == "匿名专辑")
        #expect(state.artwork == Data([1, 2, 3]))
        #expect(state.elapsed == 12)
    }

    @Test("查询完成但没有网易云候选项时返回空闲")
    func completedQueryWithoutNeteaseIsIdle() throws {
        let response = Data(#"{"complete":true,"candidates":[]}"#.utf8)

        #expect(try JXANowPlayingResponseDecoder().decode(response) == .idle)
    }

    @Test("脚本输出通过受控进程边界转换为状态")
    func scriptOutputUsesProcessBoundary() async {
        let executor = StubMediaRemoteProcessExecutor(
            capabilityResult: .success(0),
            streamLines: [
                Data(
                    #"{"complete":true,"candidates":[{"source":"supported","bundleIdentifier":"com.netease.163music","playing":false,"title":"匿名节目"}]}"#
                        .utf8
                )
            ]
        )
        let source = JXANowPlayingSnapshotSource(
            paths: .testFixture,
            executor: executor,
            requestTimeout: .seconds(1)
        )

        let state = await source.fetch()

        #expect(state.status == .paused)
        #expect(state.title == "匿名节目")
    }
}

extension JXANowPlayingPaths {
    fileprivate static let testFixture = JXANowPlayingPaths(
        osascriptExecutable: URL(fileURLWithPath: "/usr/bin/true"),
        script: URL(fileURLWithPath: "/usr/bin/true")
    )
}
