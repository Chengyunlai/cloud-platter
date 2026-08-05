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
            restartDelays: [],
            initialOutputTimeout: .seconds(1)
        )

        let capability = await source.checkCapability()

        #expect(capability == .unavailable(.capabilityTestFailed(exitCode: 23)))
    }

    @Test("能力测试超时与启动失败会被脱敏分类")
    func capabilityProcessFailuresAreClassified() async {
        let timedOutSource = MediaRemoteObservationSource(
            paths: .testFixture,
            executor: StubMediaRemoteProcessExecutor(
                capabilityResult: .failure(.timedOut),
                streamLines: []
            ),
            restartDelays: []
        )
        let launchFailedSource = MediaRemoteObservationSource(
            paths: .testFixture,
            executor: StubMediaRemoteProcessExecutor(
                capabilityResult: .failure(.launchFailed),
                streamLines: []
            ),
            restartDelays: []
        )

        #expect(await timedOutSource.checkCapability() == .unavailable(.capabilityTestTimedOut))
        #expect(await launchFailedSource.checkCapability() == .unavailable(.launchFailed))
    }

    @Test("Perl 或 helper 资源缺失时不会尝试启动")
    func missingRuntimeResourcesAreReported() async {
        let executor = StubMediaRemoteProcessExecutor(
            capabilityResult: .success(0),
            streamLines: []
        )
        let missingPerlSource = MediaRemoteObservationSource(
            paths: .testFixtureWithMissingPerl,
            executor: executor,
            restartDelays: []
        )
        let missingFrameworkSource = MediaRemoteObservationSource(
            paths: .testFixtureWithMissingFramework,
            executor: executor,
            restartDelays: []
        )

        #expect(await missingPerlSource.checkCapability() == .unavailable(.missingPerl))
        #expect(
            await missingFrameworkSource.checkCapability()
                == .unavailable(.missingResource("Missing.framework")))
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
            restartDelays: [],
            initialOutputTimeout: .seconds(1)
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
            restartDelays: [],
            initialOutputTimeout: .seconds(1)
        )
        var states: [NowPlayingState] = []

        for await state in source.states() {
            states.append(state)
        }

        #expect(states.count == 1)
        #expect(states.first?.status == .unavailable)
    }

    @Test("首包超时后进入不可用状态")
    func initialOutputTimeoutProducesUnavailableState() async {
        let executor = StubMediaRemoteProcessExecutor(
            capabilityResult: .success(0),
            streamResults: [.failure(.timedOut)]
        )
        let source = MediaRemoteObservationSource(
            paths: .testFixture,
            executor: executor,
            restartDelays: [],
            initialOutputTimeout: .milliseconds(1)
        )
        var states: [NowPlayingState] = []

        for await state in source.states() {
            states.append(state)
        }

        #expect(states.map(\.status) == [.unavailable])
        #expect(executor.streamInvocationCount == 1)
    }

    @Test("异常输出会丢弃旧快照并从新的全量事件恢复")
    func invalidOutputRestartsWithFreshSnapshot() async {
        let executor = StubMediaRemoteProcessExecutor(
            capabilityResult: .success(0),
            streamResults: [
                .success([
                    Data(
                        #"{"type":"data","diff":false,"payload":{"bundleIdentifier":"com.netease.163music","playing":true,"title":"旧歌曲"}}"#
                            .utf8
                    ),
                    Data("not-json".utf8),
                ]),
                .success([
                    Data(
                        #"{"type":"data","diff":false,"payload":{"bundleIdentifier":"com.netease.163music","playing":true,"title":"新歌曲"}}"#
                            .utf8
                    )
                ]),
            ]
        )
        let source = MediaRemoteObservationSource(
            paths: .testFixture,
            executor: executor,
            restartDelays: [.zero],
            initialOutputTimeout: .seconds(1)
        )
        var states: [NowPlayingState] = []

        for await state in source.states() {
            states.append(state)
        }

        #expect(states.map(\.title) == ["旧歌曲", "新歌曲", nil])
        #expect(states.last?.status == .unavailable)
    }

    @Test("意外退出只执行有限次数的恢复")
    func unexpectedExitHasBoundedRetries() async {
        let executor = StubMediaRemoteProcessExecutor(
            capabilityResult: .success(0),
            streamResults: [
                .failure(.terminated(exitCode: 1)),
                .failure(.terminated(exitCode: 1)),
                .failure(.terminated(exitCode: 1)),
            ]
        )
        let source = MediaRemoteObservationSource(
            paths: .testFixture,
            executor: executor,
            restartDelays: [.zero, .zero],
            initialOutputTimeout: .seconds(1)
        )
        var states: [NowPlayingState] = []

        for await state in source.states() {
            states.append(state)
        }

        #expect(states.map(\.status) == [.unavailable])
        #expect(executor.streamInvocationCount == 3)
    }

    @Test("短重试耗尽后仍会在冷却周期恢复")
    func recoveryContinuesAfterBoundedRetryCycle() async {
        let executor = StubMediaRemoteProcessExecutor(
            capabilityResult: .success(0),
            streamResults: [
                .success([
                    Data(
                        #"{"type":"data","diff":false,"payload":{"bundleIdentifier":"com.netease.163music","playing":true,"title":"初始节目"}}"#
                            .utf8
                    )
                ]),
                .failure(.terminated(exitCode: 1)),
                .success([
                    Data(
                        #"{"type":"data","diff":false,"payload":{"bundleIdentifier":"com.netease.163music","playing":true,"title":"恢复节目"}}"#
                            .utf8
                    )
                ]),
            ]
        )
        let source = MediaRemoteObservationSource(
            paths: .testFixture,
            executor: executor,
            restartDelays: [.zero],
            initialOutputTimeout: .seconds(1),
            recoveryCooldown: .zero,
            maximumRecoveryCycles: 2
        )
        var recovered = false

        for await state in source.states() {
            if state.title == "恢复节目" {
                recovered = true
                break
            }
        }

        #expect(recovered)
        #expect((3...4).contains(executor.streamInvocationCount))
    }
}

extension MediaRemoteAdapterPaths {
    fileprivate static let testFixture = MediaRemoteAdapterPaths(
        perlExecutable: URL(fileURLWithPath: "/usr/bin/true"),
        supervisor: URL(fileURLWithPath: "/usr/bin/true"),
        script: URL(fileURLWithPath: "/usr/bin/true"),
        framework: URL(fileURLWithPath: "/System/Library/Frameworks/Foundation.framework"),
        testClient: URL(fileURLWithPath: "/usr/bin/true")
    )

    fileprivate static let testFixtureWithMissingPerl = MediaRemoteAdapterPaths(
        perlExecutable: URL(fileURLWithPath: "/不存在/perl"),
        supervisor: URL(fileURLWithPath: "/usr/bin/true"),
        script: URL(fileURLWithPath: "/usr/bin/true"),
        framework: URL(fileURLWithPath: "/System/Library/Frameworks/Foundation.framework"),
        testClient: URL(fileURLWithPath: "/usr/bin/true")
    )

    fileprivate static let testFixtureWithMissingFramework = MediaRemoteAdapterPaths(
        perlExecutable: URL(fileURLWithPath: "/usr/bin/true"),
        supervisor: URL(fileURLWithPath: "/usr/bin/true"),
        script: URL(fileURLWithPath: "/usr/bin/true"),
        framework: URL(fileURLWithPath: "/不存在/Missing.framework"),
        testClient: URL(fileURLWithPath: "/usr/bin/true")
    )
}
