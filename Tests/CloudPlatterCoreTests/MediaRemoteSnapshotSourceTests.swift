import Foundation
import Testing

@testable import CloudPlatterCore

@Suite("MediaRemote 一次性播放快照")
struct MediaRemoteSnapshotSourceTests {
    @Test("一次性快照通过受控进程边界转换为播放状态")
    func snapshotProcessOutputBecomesPlayingState() async {
        let executor = StubMediaRemoteProcessExecutor(
            capabilityResult: .success(0),
            streamLines: [
                Data(
                    #"{"bundleIdentifier":"com.netease.163music","playing":true,"title":"匿名歌曲","artist":"匿名艺人","album":"匿名专辑","artworkData":"AQID"}"#
                        .utf8
                )
            ]
        )
        let source = MediaRemoteNowPlayingSnapshotSource(
            paths: .snapshotTestFixture,
            executor: executor,
            requestTimeout: .seconds(1)
        )

        let state = await source.fetch()

        #expect(state.status == .playing)
        #expect(state.title == "匿名歌曲")
        #expect(state.artist == "匿名艺人")
        #expect(state.album == "匿名专辑")
        #expect(state.artwork == Data([1, 2, 3]))
    }

    @Test("一次性查询超时时返回脱敏的不可用状态")
    func snapshotTimeoutBecomesUnavailable() async {
        let executor = StubMediaRemoteProcessExecutor(
            capabilityResult: .success(0),
            streamResults: [.failure(.timedOut)]
        )
        let source = MediaRemoteNowPlayingSnapshotSource(
            paths: .snapshotTestFixture,
            executor: executor,
            requestTimeout: .milliseconds(10)
        )

        #expect(await source.fetch().status == .unavailable)
    }
}

extension MediaRemoteAdapterPaths {
    fileprivate static let snapshotTestFixture = MediaRemoteAdapterPaths(
        perlExecutable: URL(fileURLWithPath: "/usr/bin/true"),
        supervisor: URL(fileURLWithPath: "/usr/bin/true"),
        script: URL(fileURLWithPath: "/usr/bin/true"),
        framework: URL(fileURLWithPath: "/System/Library/Frameworks/Foundation.framework"),
        testClient: URL(fileURLWithPath: "/usr/bin/true")
    )
}
