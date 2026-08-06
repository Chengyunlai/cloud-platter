import CoreGraphics

/// 统一唱臂各部件的比例和落针轨迹，避免视觉绘制与命中位置各自计算。
struct DesktopSceneTonearmLayout: Equatable {
    let size: CGSize

    var pivotPoint: CGPoint {
        CGPoint(x: size.width * 0.5, y: size.width * 0.32)
    }

    var tubeLength: CGFloat {
        size.height * 0.52
    }

    var tubeEndPoint: CGPoint {
        CGPoint(
            x: pivotPoint.x - size.width * 0.035,
            y: pivotPoint.y + tubeLength
        )
    }

    var stylusPointBeforeRotation: CGPoint {
        CGPoint(
            x: pivotPoint.x - size.width * 0.05,
            y: pivotPoint.y + size.height * 0.71
        )
    }

    func rotationDegrees(isEngaged: Bool) -> Double {
        isEngaged ? 48 : 7
    }

    func stylusPoint(isEngaged: Bool) -> CGPoint {
        let angle = rotationDegrees(isEngaged: isEngaged) * .pi / 180
        let offsetX = stylusPointBeforeRotation.x - pivotPoint.x
        let offsetY = stylusPointBeforeRotation.y - pivotPoint.y

        return CGPoint(
            x: pivotPoint.x + offsetX * cos(angle) - offsetY * sin(angle),
            y: pivotPoint.y + offsetX * sin(angle) + offsetY * cos(angle)
        )
    }
}
