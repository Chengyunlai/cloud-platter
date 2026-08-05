import Foundation
import Testing

@testable import CloudPlatterCore

@Suite("MediaRemote 播放状态源")
struct MediaRemoteObservationSourceTests {
    @Test("能力测试失败时返回可解释的不可用原因")
    func failedCapabilityTestIsReported() async {
        let executor = StubMediaRemoteProcessExecutor(
            capabilityResult: .success(23),
            streamLines: []
        )
        let source = MediaRemoteObservationSource(
            paths: .testFixture,
            executor: executor,
            restartDelays: []
        )

        let capability = await source.checkCapability()

        #expect(capability == .unavailable(.capabilityTestFailed(exitCode: 23)))
    }

    @Test("事件流通过公开状态序列输出规范化结果")
    func streamProducesNormalizedStates() async throws {
        let executor = StubMediaRemoteProcessExecutor(
            capabilityResult: .success(0),
            streamLines: [
                Data(
                    #"{"type":"data","diff":false,"payload":{"bundleIdentifier":"com.netease.163music","playing":true,"title":"第一首","artist":"测试艺人"}}"#
                        .utf8
                ),
                Data(
                    #"{"type":"data","diff":true,"payload":{"playing":false,"title":"第二首"}}"#.utf8
                ),
            ]
        )
        let source = MediaRemoteObservationSource(
            paths: .testFixture,
            executor: executor,
            restartDelays: []
        )
        var states: [NowPlayingState] = []

        for await state in source.states().prefix(2) {
            states.append(state)
        }

        #expect(states.map(\.title) == ["第一首", "第二首"])
        #expect(states.map(\.status) == [.playing, .paused])
    }

    @Test("能力不可用时状态序列安全降级后结束")
    func unavailableCapabilityProducesUnavailableState() async {
        let executor = StubMediaRemoteProcessExecutor(
            capabilityResult: .success(9),
            streamLines: []
        )
        let source = MediaRemoteObservationSource(
            paths: .testFixture,
            executor: executor,
            restartDelays: []
        )
        var states: [NowPlayingState] = []

        for await state in source.states() {
            states.append(state)
        }

        #expect(states.count == 1)
        #expect(states.first?.status == .unavailable)
    }
}

private final class StubMediaRemoteProcessExecutor: MediaRemoteProcessExecuting,
    @unchecked Sendable
{
    let capabilityResult: Result<Int32, MediaRemoteProcessError>
    let streamLines: [Data]

    init(
        capabilityResult: Result<Int32, MediaRemoteProcessError>,
        streamLines: [Data]
    ) {
        self.capabilityResult = capabilityResult
        self.streamLines = streamLines
    }

    func run(arguments: [String], timeout: Duration) async
        -> Result<Int32, MediaRemoteProcessError>
    {
        capabilityResult
    }

    func lines(arguments: [String]) -> AsyncThrowingStream<Data, any Error> {
        let streamLines = streamLines
        return AsyncThrowingStream { continuation in
            for line in streamLines {
                continuation.yield(line)
            }
            continuation.finish()
        }
    }
}

extension MediaRemoteAdapterPaths {
    fileprivate static let testFixture = MediaRemoteAdapterPaths(
        perlExecutable: URL(fileURLWithPath: "/usr/bin/true"),
        script: URL(fileURLWithPath: "/usr/bin/true"),
        framework: URL(fileURLWithPath: "/System/Library/Frameworks/Foundation.framework"),
        testClient: URL(fileURLWithPath: "/usr/bin/true")
    )
}
