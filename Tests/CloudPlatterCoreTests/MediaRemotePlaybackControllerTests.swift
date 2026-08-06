import Foundation
import Testing

@testable import CloudPlatterCore

@Suite("MediaRemote 播放控制")
struct MediaRemotePlaybackControllerTests {
    @Test("三种用户命令映射到约定的 Adapter 编号")
    func commandsMapToAdapterIdentifiers() async {
        let executor = makeExecutor()
        let controller = MediaRemotePlaybackController(
            paths: .playbackControlTestFixture,
            executor: executor,
            requestTimeout: .seconds(1)
        )

        let previousResult = await controller.send(.previousTrack)
        let toggleResult = await controller.send(.togglePlayPause)
        let nextResult = await controller.send(.nextTrack)

        #expect(previousResult == .sent)
        #expect(toggleResult == .sent)
        #expect(nextResult == .sent)
        #expect(
            executor.runArguments.map(\.suffixCommandArguments)
                == [
                    ["send", "5"],
                    ["send", "2"],
                    ["send", "4"],
                ]
        )
    }

    @Test("来源变化时拒绝控制其他播放器")
    func unsupportedSourceDoesNotReceiveCommand() async {
        let executor = StubMediaRemoteProcessExecutor(
            capabilityResult: .success(0),
            streamLines: [
                Data(
                    #"{"bundleIdentifier":"com.apple.Music","playing":true,"title":"匿名歌曲"}"#
                        .utf8
                )
            ]
        )
        let controller = makeController(executor: executor)

        let result = await controller.send(.nextTrack)

        #expect(result == .failed(.unsupportedSource))
        #expect(executor.runArguments.isEmpty)
    }

    @Test("即时来源复核失败时返回不可用且不发送命令")
    func unavailableSnapshotDoesNotSendCommand() async {
        let executor = StubMediaRemoteProcessExecutor(
            capabilityResult: .success(0),
            streamResults: [.failure(.timedOut)]
        )
        let controller = makeController(executor: executor)

        let result = await controller.send(.togglePlayPause)

        #expect(result == .failed(.unavailable))
        #expect(executor.runArguments.isEmpty)
    }

    @Test("Adapter 拒绝命令时返回脱敏失败")
    func rejectedCommandReturnsSanitizedFailure() async {
        let executor = StubMediaRemoteProcessExecutor(
            capabilityResult: .success(9),
            streamLines: [
                Data(
                    #"{"bundleIdentifier":"com.netease.163music","playing":false,"title":"匿名歌曲"}"#
                        .utf8
                )
            ]
        )
        let controller = makeController(executor: executor)

        #expect(await controller.send(.previousTrack) == .failed(.commandRejected))
    }

    private func makeExecutor() -> StubMediaRemoteProcessExecutor {
        StubMediaRemoteProcessExecutor(
            capabilityResult: .success(0),
            streamLines: [
                Data(
                    #"{"bundleIdentifier":"com.netease.163music","playing":true,"title":"匿名歌曲"}"#
                        .utf8
                )
            ]
        )
    }

    private func makeController(
        executor: StubMediaRemoteProcessExecutor
    ) -> MediaRemotePlaybackController {
        MediaRemotePlaybackController(
            paths: .playbackControlTestFixture,
            executor: executor,
            requestTimeout: .seconds(1)
        )
    }
}

extension MediaRemoteAdapterPaths {
    fileprivate static let playbackControlTestFixture = MediaRemoteAdapterPaths(
        perlExecutable: URL(fileURLWithPath: "/usr/bin/true"),
        supervisor: URL(fileURLWithPath: "/usr/bin/true"),
        script: URL(fileURLWithPath: "/usr/bin/true"),
        framework: URL(fileURLWithPath: "/System/Library/Frameworks/Foundation.framework"),
        testClient: URL(fileURLWithPath: "/usr/bin/true")
    )
}

extension Array where Element == String {
    fileprivate var suffixCommandArguments: [String] {
        Array(suffix(2))
    }
}
