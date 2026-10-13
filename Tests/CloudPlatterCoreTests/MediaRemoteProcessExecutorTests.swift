import Darwin
import Foundation
import Testing

@testable import CloudPlatterCore

@Suite("真实子进程生命周期")
struct MediaRemoteProcessExecutorTests {
    @Test("正常退出保留退出码", arguments: [0, 7])
    func normalExitPreservesStatus(_ status: Int32) async {
        let executor = FoundationMediaRemoteProcessExecutor(
            executable: URL(fileURLWithPath: "/bin/sh")
        )
        #expect(
            await executor.run(arguments: ["-c", "exit \(status)"], timeout: .seconds(2))
                == .success(status)
        )
    }

    @Test("取消已经启动的任务会终止真实子进程")
    func cancellationTerminatesRunningProcess() async throws {
        let fixture = try ProcessFixture()
        defer { fixture.remove() }
        let task = Task { await fixture.run(timeout: .seconds(5)) }
        let pid = try await fixture.waitForPID()
        let clock = ContinuousClock()
        let cancelledAt = clock.now

        task.cancel()

        #expect(await task.value == .failure(.cancelled))
        #expect(cancelledAt.duration(to: clock.now) < .seconds(1))
        #expect(await fixture.waitUntilExited(pid))
    }

    @Test("启动前取消不会执行命令")
    func cancellationBeforeLaunchDoesNotStartProcess() async throws {
        let fixture = try ProcessFixture()
        defer { fixture.remove() }
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return await fixture.run(timeout: .seconds(2))
        }

        #expect(await task.value == .failure(.cancelled))
        #expect(!FileManager.default.fileExists(atPath: fixture.pidFile.path))
    }

    @Test("超时会终止真实子进程且返回超时分类")
    func timeoutTerminatesProcess() async throws {
        let fixture = try ProcessFixture()
        defer { fixture.remove() }
        let task = Task { await fixture.run(timeout: .milliseconds(200)) }
        let pid = try await fixture.waitForPID()

        #expect(await task.value == .failure(.timedOut))
        #expect(await fixture.waitUntilExited(pid))
    }

    @Test("退出与取消同时发生时只完成一次")
    func exitAndCancellationRaceCompletes() async {
        let executor = FoundationMediaRemoteProcessExecutor(
            executable: URL(fileURLWithPath: "/usr/bin/true")
        )
        for _ in 0..<20 {
            let task = Task { await executor.run(arguments: [], timeout: .seconds(2)) }
            await Task.yield()
            task.cancel()
            let result = await task.value
            #expect(result == .success(0) || result == .failure(.cancelled))
        }
    }
}

private struct ProcessFixture: Sendable {
    let directory: URL
    let pidFile: URL

    init() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        pidFile = directory.appendingPathComponent("child.pid")
    }

    func run(timeout: Duration) async -> Result<Int32, MediaRemoteProcessError> {
        let executor = FoundationMediaRemoteProcessExecutor(
            executable: URL(fileURLWithPath: "/bin/sh")
        )
        // 使用位置参数传路径，测试命令不包含用户媒体，也不依赖路径中的特殊字符。
        return await executor.run(
            arguments: ["-c", "echo $$ > \"$1\"; exec /bin/sleep 5", "fixture", pidFile.path],
            timeout: timeout
        )
    }

    func waitForPID() async throws -> Int32 {
        for _ in 0..<100 {
            if let value = try? String(contentsOf: pidFile, encoding: .utf8),
                let pid = Int32(value.trimmingCharacters(in: .whitespacesAndNewlines))
            {
                return pid
            }
            try await Task.sleep(for: .milliseconds(10))
        }
        throw FixtureError.processDidNotStart
    }

    func waitUntilExited(_ pid: Int32) async -> Bool {
        for _ in 0..<100 {
            if kill(pid, 0) != 0 { return true }
            try? await Task.sleep(for: .milliseconds(10))
        }
        return false
    }

    func remove() {
        try? FileManager.default.removeItem(at: directory)
    }
}

private enum FixtureError: Error {
    case processDidNotStart
}
