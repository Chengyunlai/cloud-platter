import Foundation

@testable import CloudPlatterCore

final class StubMediaRemoteProcessExecutor: MediaRemoteProcessExecuting,
    @unchecked Sendable
{
    let capabilityResult: Result<Int32, MediaRemoteProcessError>
    private let lock = NSLock()
    private let streamResults: [Result<[Data], MediaRemoteProcessError>]
    private let streamDelay: Duration
    private var nextStreamIndex = 0
    private var recordedRunArguments: [[String]] = []
    private var recordedRunTimeouts: [Duration] = []
    private var recordedInitialOutputTimeouts: [Duration] = []

    var streamInvocationCount: Int {
        lock.withLock { nextStreamIndex }
    }

    var runArguments: [[String]] {
        lock.withLock { recordedRunArguments }
    }

    var runTimeouts: [Duration] {
        lock.withLock { recordedRunTimeouts }
    }

    var initialOutputTimeouts: [Duration] {
        lock.withLock { recordedInitialOutputTimeouts }
    }

    init(
        capabilityResult: Result<Int32, MediaRemoteProcessError>,
        streamLines: [Data],
        streamDelay: Duration = .zero
    ) {
        self.capabilityResult = capabilityResult
        streamResults = [.success(streamLines)]
        self.streamDelay = streamDelay
    }

    init(
        capabilityResult: Result<Int32, MediaRemoteProcessError>,
        streamResults: [Result<[Data], MediaRemoteProcessError>],
        streamDelay: Duration = .zero
    ) {
        self.capabilityResult = capabilityResult
        self.streamResults = streamResults
        self.streamDelay = streamDelay
    }

    func run(arguments: [String], timeout: Duration) async
        -> Result<Int32, MediaRemoteProcessError>
    {
        lock.withLock {
            recordedRunArguments.append(arguments)
            recordedRunTimeouts.append(timeout)
        }
        return capabilityResult
    }

    func lines(arguments: [String], initialOutputTimeout: Duration)
        -> AsyncThrowingStream<Data, any Error>
    {
        lock.withLock {
            recordedInitialOutputTimeouts.append(initialOutputTimeout)
        }

        let result = lock.withLock {
            let result = streamResults[min(nextStreamIndex, streamResults.count - 1)]
            nextStreamIndex += 1
            return result
        }

        return AsyncThrowingStream { continuation in
            Task {
                if streamDelay > .zero {
                    try? await Task.sleep(for: streamDelay)
                }

                switch result {
                case .success(let lines):
                    for line in lines {
                        continuation.yield(line)
                    }
                    continuation.finish()
                case .failure(let error):
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
