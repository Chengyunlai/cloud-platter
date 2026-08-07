import CoreGraphics

/// 统一唱盘与唱臂在机身内的相对位置，并提供可验证的落针半径。
struct DesktopSceneTurntableLayout: Equatable {
    let size: CGSize

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
            y: size.height * 0.43 - frameSize.height / 2,
            width: frameSize.width,
            height: frameSize.height
        )
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
