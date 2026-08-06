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

    @Test("MediaRemote 读取受限时使用网易云定向复核后发送命令")
    func unavailableMediaRemoteValidationFallsBackToNeteaseQuery() async {
        let executor = StubMediaRemoteProcessExecutor(
            capabilityResult: .success(0),
            streamResults: [.failure(.timedOut)]
        )
        let controller = MediaRemotePlaybackController(
            paths: .playbackControlTestFixture,
            executor: executor,
            fallbackTargetValidator: StubPlaybackTargetValidator(result: .supported),
            requestTimeout: .seconds(1)
        )

        #expect(await controller.send(.togglePlayPause) == .sent)
        #expect(executor.runArguments.map(\.suffixCommandArguments) == [["send", "2"]])
    }

    @Test("定向复核未确认网易云时仍不发送命令")
    func unsupportedFallbackValidationDoesNotSendCommand() async {
        let executor = StubMediaRemoteProcessExecutor(
            capabilityResult: .success(0),
            streamResults: [.failure(.timedOut)]
        )
        let controller = MediaRemotePlaybackController(
            paths: .playbackControlTestFixture,
            executor: executor,
            fallbackTargetValidator: StubPlaybackTargetValidator(result: .unsupported),
            requestTimeout: .seconds(1)
        )

        #expect(await controller.send(.nextTrack) == .failed(.unsupportedSource))
        #expect(executor.runArguments.isEmpty)
    }

    @Test("定向复核不可用时安全降级且不发送命令")
    func unavailableFallbackValidationDoesNotSendCommand() async {
        let executor = StubMediaRemoteProcessExecutor(
            capabilityResult: .success(0),
            streamResults: [.failure(.timedOut)]
        )
        let controller = MediaRemotePlaybackController(
            paths: .playbackControlTestFixture,
            executor: executor,
            fallbackTargetValidator: StubPlaybackTargetValidator(result: .unavailable),
            requestTimeout: .seconds(1)
        )

        #expect(await controller.send(.nextTrack) == .failed(.unavailable))
        #expect(executor.runArguments.isEmpty)
    }

    @Test("主复核超时时仍为定向复核保留预算")
    func timedOutPrimaryLeavesBudgetForFallbackValidation() async {
        let executor = StubMediaRemoteProcessExecutor(
            capabilityResult: .success(0),
            streamResults: [.failure(.timedOut)],
            streamDelay: .milliseconds(250)
        )
        let validator = StubPlaybackTargetValidator(result: .supported)
        let controller = MediaRemotePlaybackController(
            paths: .playbackControlTestFixture,
            executor: executor,
            fallbackTargetValidator: validator,
            requestTimeout: .seconds(1)
        )

        #expect(await controller.send(.togglePlayPause) == .sent)
        #expect(
            executor.initialOutputTimeouts.first
                == PlaybackControlTiming.mediaRemoteValidationTimeout
        )
        #expect(validator.timeouts.first != nil)
        if let fallbackTimeout = validator.timeouts.first {
            #expect(fallbackTimeout > .zero)
            #expect(fallbackTimeout <= PlaybackControlTiming.fallbackValidationTimeout)
        }
    }

    @Test("定向复核耗尽总预算后禁止发送命令")
    func exhaustedFallbackBudgetDoesNotSendCommand() async {
        let executor = StubMediaRemoteProcessExecutor(
            capabilityResult: .success(0),
            streamResults: [.failure(.timedOut)]
        )
        let controller = MediaRemotePlaybackController(
            paths: .playbackControlTestFixture,
            executor: executor,
            fallbackTargetValidator: StubPlaybackTargetValidator(
                result: .supported,
                delay: .milliseconds(350)
            ),
            requestTimeout: .milliseconds(300)
        )

        #expect(await controller.send(.togglePlayPause) == .failed(.unavailable))
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

    @Test("命令进程不可用时不会误报为网易云拒绝")
    func unavailableCommandProcessReturnsUnavailable() async {
        let executor = StubMediaRemoteProcessExecutor(
            capabilityResult: .failure(.timedOut),
            streamLines: [
                Data(
                    #"{"bundleIdentifier":"com.netease.163music","playing":true,"title":"匿名歌曲"}"#
                        .utf8
                )
            ]
        )
        let controller = makeController(executor: executor)

        #expect(await controller.send(.nextTrack) == .failed(.unavailable))
    }

    @Test("来源复核与命令发送共享一个总超时预算")
    func validationAndCommandShareOneTimeoutBudget() async {
        let executor = StubMediaRemoteProcessExecutor(
            capabilityResult: .success(0),
            streamLines: [
                Data(
                    #"{"bundleIdentifier":"com.netease.163music","playing":true,"title":"匿名歌曲"}"#
                        .utf8
                )
            ],
            streamDelay: .milliseconds(100)
        )
        let controller = MediaRemotePlaybackController(
            paths: .playbackControlTestFixture,
            executor: executor,
            requestTimeout: .milliseconds(500)
        )

        #expect(await controller.send(.togglePlayPause) == .sent)
        let validationTimeout = executor.initialOutputTimeouts.first
        let commandTimeout = executor.runTimeouts.first
        #expect(validationTimeout != nil)
        #expect(commandTimeout != nil)
        if let validationTimeout, let commandTimeout {
            #expect(validationTimeout <= PlaybackControlTiming.mediaRemoteValidationTimeout)
            #expect(commandTimeout < .milliseconds(500))
        }
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

private final class StubPlaybackTargetValidator: PlaybackTargetValidating,
    @unchecked Sendable
{
    private let lock = NSLock()
    private let result: PlaybackTargetValidation
    private let delay: Duration
    private var recordedTimeouts: [Duration] = []

    var timeouts: [Duration] {
        lock.withLock { recordedTimeouts }
    }

    init(result: PlaybackTargetValidation, delay: Duration = .zero) {
        self.result = result
        self.delay = delay
    }

    func validate(timeout: Duration) async -> PlaybackTargetValidation {
        lock.withLock {
            recordedTimeouts.append(timeout)
        }
        if delay > .zero {
            try? await Task.sleep(for: delay)
        }
        return result
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
