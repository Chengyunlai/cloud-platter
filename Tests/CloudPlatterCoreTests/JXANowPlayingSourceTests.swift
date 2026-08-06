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

    @Test("控制复核只接受系统全局当前目标为网易云")
    func playbackTargetValidationAcceptsGlobalNetease() throws {
        let response = Data(
            #"{"complete":true,"candidates":[{"source":"global","bundleIdentifier":"com.netease.163music","playing":true,"title":"匿名歌曲"},{"source":"supported","bundleIdentifier":"com.netease.163music","playing":true,"title":"匿名歌曲"}]}"#
                .utf8
        )

        #expect(
            try JXANowPlayingResponseDecoder().decodePlaybackTarget(response)
                == .supported
        )
    }

    @Test("其他播放器成为全局目标时不使用网易云残留状态发送命令")
    func playbackTargetValidationRejectsStaleNeteaseCandidate() throws {
        let response = Data(
            #"{"complete":true,"candidates":[{"source":"global","bundleIdentifier":"com.apple.Music","playing":true,"title":"匿名歌曲一"},{"source":"supported","bundleIdentifier":"com.netease.163music","playing":true,"title":"匿名歌曲二"}]}"#
                .utf8
        )

        #expect(
            try JXANowPlayingResponseDecoder().decodePlaybackTarget(response)
                == .unsupported
        )
    }

    @Test("控制复核响应不完整或缺少播放字段时返回不可用")
    func playbackTargetValidationRequiresCompleteGlobalFields() throws {
        let incompleteResponse = Data(
            #"{"complete":false,"candidates":[{"source":"global","bundleIdentifier":"com.netease.163music","playing":true,"title":"匿名歌曲"}]}"#
                .utf8
        )
        let missingFieldsResponse = Data(
            #"{"complete":true,"candidates":[{"source":"global","bundleIdentifier":"com.netease.163music","title":"匿名歌曲"}]}"#
                .utf8
        )

        let decoder = JXANowPlayingResponseDecoder()
        #expect(try decoder.decodePlaybackTarget(incompleteResponse) == .unavailable)
        #expect(try decoder.decodePlaybackTarget(missingFieldsResponse) == .unavailable)
    }

    @Test("JXA 控制复核通过受控进程边界读取全局目标")
    func playbackTargetValidatorUsesProcessBoundary() async {
        let executor = StubMediaRemoteProcessExecutor(
            capabilityResult: .success(0),
            streamLines: [
                Data(
                    #"{"complete":true,"candidates":[{"source":"global","bundleIdentifier":"com.netease.163music","playing":false,"title":"匿名节目"}]}"#
                        .utf8
                )
            ]
        )
        let validator = JXAPlaybackTargetValidator(
            paths: .testFixture,
            executor: executor
        )
        let timeout = Duration.milliseconds(321)

        #expect(await validator.validate(timeout: timeout) == .supported)
        #expect(executor.initialOutputTimeouts == [timeout])
    }

    @Test("JXA 控制复核进程超时时返回不可用")
    func playbackTargetValidatorTimeoutBecomesUnavailable() async {
        let executor = StubMediaRemoteProcessExecutor(
            capabilityResult: .success(0),
            streamResults: [.failure(.timedOut)]
        )
        let validator = JXAPlaybackTargetValidator(
            paths: .testFixture,
            executor: executor
        )

        #expect(
            await validator.validate(timeout: .milliseconds(10))
                == .unavailable
        )
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

    @Test("查询超时时返回脱敏的不可用状态")
    func timeoutBecomesUnavailable() async {
        let executor = StubMediaRemoteProcessExecutor(
            capabilityResult: .success(0),
            streamResults: [.failure(.timedOut)]
        )
        let source = JXANowPlayingSnapshotSource(
            paths: .testFixture,
            executor: executor,
            requestTimeout: .milliseconds(10)
        )

        #expect(await source.fetch().status == .unavailable)
    }

    @Test("取消查询时结束受控进程流")
    func cancellationTerminatesProcessStream() async throws {
        let executor = CancellationRecordingProcessExecutor()
        let source = JXANowPlayingSnapshotSource(
            paths: .testFixture,
            executor: executor,
            requestTimeout: .seconds(1)
        )
        let task = Task {
            await source.fetch()
        }

        for _ in 0..<100 where !executor.hasStarted {
            await Task.yield()
        }
        #expect(executor.hasStarted)
        task.cancel()

        #expect(await task.value.status == .unavailable)
        try await Task.sleep(for: .milliseconds(20))
        #expect(executor.wasCancelled)
    }
}

extension JXANowPlayingPaths {
    fileprivate static let testFixture = JXANowPlayingPaths(
        osascriptExecutable: URL(fileURLWithPath: "/usr/bin/true"),
        script: URL(fileURLWithPath: "/usr/bin/true")
    )
}

private final class CancellationRecordingProcessExecutor: MediaRemoteProcessExecuting,
    @unchecked Sendable
{
    private let lock = NSLock()
    private var didStart = false
    private var didCancel = false

    var hasStarted: Bool {
        lock.withLock { didStart }
    }

    var wasCancelled: Bool {
        lock.withLock { didCancel }
    }

    func run(arguments: [String], timeout: Duration) async
        -> Result<Int32, MediaRemoteProcessError>
    {
        .success(0)
    }

    func lines(arguments: [String], initialOutputTimeout: Duration)
        -> AsyncThrowingStream<Data, any Error>
    {
        lock.withLock {
            didStart = true
        }
        return AsyncThrowingStream { continuation in
            continuation.onTermination = { [weak self] _ in
                self?.lock.withLock {
                    self?.didCancel = true
                }
            }
        }
    }
}
