import Foundation

struct RecordRotationState: Equatable {
    private static let degreesPerSecond = 18.0
    private static let stoppingTravel = 6.0

    private(set) var isAnimating = false
    private var baseAngle = 0.0
    private var startedAt = Date(timeIntervalSinceReferenceDate: 0)
    private var stoppedAngle = 0.0

    mutating func start(at date: Date) {
        guard !isAnimating else {
            return
        }
        baseAngle = stoppedAngle
        startedAt = date
        isAnimating = true
    }

    mutating func stop(at date: Date) {
        guard isAnimating else {
            return
        }
        stoppedAngle = angle(at: date) + Self.stoppingTravel
        isAnimating = false
    }

    func angle(at date: Date) -> Double {
        guard isAnimating else {
            return stoppedAngle
        }
        let elapsed = max(0, date.timeIntervalSince(startedAt))
        return baseAngle + elapsed * Self.degreesPerSecond
    }
}
