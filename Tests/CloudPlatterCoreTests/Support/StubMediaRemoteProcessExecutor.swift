import Foundation

@testable import CloudPlatterCore

final class StubMediaRemoteProcessExecutor: MediaRemoteProcessExecuting,
    @unchecked Sendable
{
    let capabilityResult: Result<Int32, MediaRemoteProcessError>
    private let lock = NSLock()
    private let streamResults: [Result<[Data], MediaRemoteProcessError>]
    private var nextStreamIndex = 0

    var streamInvocationCount: Int {
        lock.withLock { nextStreamIndex }
    }

    init(
        capabilityResult: Result<Int32, MediaRemoteProcessError>,
        streamLines: [Data]
    ) {
        self.capabilityResult = capabilityResult
        streamResults = [.success(streamLines)]
    }

    init(
        capabilityResult: Result<Int32, MediaRemoteProcessError>,
        streamResults: [Result<[Data], MediaRemoteProcessError>]
    ) {
        self.capabilityResult = capabilityResult
        self.streamResults = streamResults
    }

    func run(arguments: [String], timeout: Duration) async
        -> Result<Int32, MediaRemoteProcessError>
    {
        capabilityResult
    }

    func lines(arguments: [String], initialOutputTimeout: Duration)
        -> AsyncThrowingStream<Data, any Error>
    {
        let result = lock.withLock {
            let result = streamResults[min(nextStreamIndex, streamResults.count - 1)]
            nextStreamIndex += 1
            return result
        }

        return AsyncThrowingStream { continuation in
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
