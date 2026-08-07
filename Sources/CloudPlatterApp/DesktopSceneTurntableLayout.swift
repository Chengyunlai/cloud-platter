import CoreGraphics

/// 统一唱盘与唱臂在机身内的相对位置，并提供可验证的落针半径。
struct DesktopSceneTurntableLayout: Equatable {
    let size: CGSize

    /// 避开素材圆角与木框的白色台面安全区。
    var whiteDeckSafeFrame: CGRect {
        CGRect(
            x: size.width * 0.035,
            y: size.height * 0.08,
            width: size.width * 0.93,
            height: size.height * 0.78
        )
    }

    var recordDiameter: CGFloat {
        min(size.width * 0.48, size.height * 0.72)
    }

    var recordCenter: CGPoint {
        CGPoint(x: size.width * 0.35, y: size.height * 0.5)
    }

    var tonearmFrame: CGRect {
        let frameSize = CGSize(width: size.width * 0.18, height: size.height * 0.72)
        return CGRect(
            x: size.width * 0.8 - frameSize.width / 2,
            y: size.height * 0.475 - frameSize.height / 2,
            width: frameSize.width,
            height: frameSize.height
        )
    }

    var speedKnobFrame: CGRect {
        let side = size.width * 0.085
        return CGRect(
            x: size.width * 0.89 - side / 2,
            y: size.height * 0.71 - side / 2,
            width: side,
            height: side
        )
    }

    var brandPlaqueFrame: CGRect {
        let plaqueSize = CGSize(width: size.width * 0.18, height: size.height * 0.065)
        return CGRect(
            x: size.width * 0.855 - plaqueSize.width / 2,
            y: size.height * 0.825 - plaqueSize.height / 2,
            width: plaqueSize.width,
            height: plaqueSize.height
        )
    }

    var tonearmPivotBaseFrame: CGRect {
        let localFrame = DesktopSceneMaterialTonearmLayout(size: tonearmFrame.size)
            .pivotBaseFrame
        return localFrame.offsetBy(dx: tonearmFrame.minX, dy: tonearmFrame.minY)
    }

    func stylusPoint(isEngaged: Bool) -> CGPoint {
        let localPoint = DesktopSceneMaterialTonearmLayout(size: tonearmFrame.size)
            .stylusPoint(isEngaged: isEngaged)
        return CGPoint(
            x: tonearmFrame.minX + localPoint.x,
            y: tonearmFrame.minY + localPoint.y
        )
    }

    func stylusRadiusRatio(isEngaged: Bool) -> CGFloat {
        let point = stylusPoint(isEngaged: isEngaged)
        let distance = hypot(point.x - recordCenter.x, point.y - recordCenter.y)
        return distance / (recordDiameter / 2)
    }
}
