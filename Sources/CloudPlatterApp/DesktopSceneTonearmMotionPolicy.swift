import Foundation

/// 以两段不同周期的轻微旋转模拟唱针循迹，避免规则钟摆感。
struct DesktopSceneTonearmMotionPolicy: Equatable {
    let isEngaged: Bool
    let shouldAnimate: Bool
    let reduceMotion: Bool

    func wobbleDegrees(at date: Date) -> Double {
        guard isEngaged, shouldAnimate, !reduceMotion else {
            return 0
        }

        let seconds = date.timeIntervalSinceReferenceDate
        let primary = sin(seconds * 2 * .pi / 3.2) * 0.18
        let secondary = sin(seconds * 2 * .pi / 1.1 + 0.7) * 0.06
        return primary + secondary
    }
}
