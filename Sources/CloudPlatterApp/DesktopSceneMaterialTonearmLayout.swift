import CoreGraphics

/// 统一完整素材唱臂的像素锚点、缩放比例和落针轨迹。
struct DesktopSceneMaterialTonearmLayout: Equatable {
    let size: CGSize

    // 完整唱臂扩展为 1500×1500 透明画布，机械轴心固定在画布中心。
    private enum MaterialMetrics {
        static let assemblyWidthMultiplier: CGFloat = 3.25
        static let stylusAnchor = CGPoint(
            x: CGFloat(259) / 1500,
            y: CGFloat(1392) / 1500
        )

        // 固定底座裁切尺寸为 440×552，中心圆盘是唱臂的静态轴座。
        static let pivotBaseWidthMultiplier: CGFloat = 0.95
        static let pivotBaseAspectRatio: CGFloat = CGFloat(552) / 440
        static let pivotBaseAnchor = CGPoint(
            x: CGFloat(205) / 440,
            y: CGFloat(205) / 552
        )
    }

    var pivotPoint: CGPoint {
        CGPoint(x: size.width * 0.5, y: size.width * 0.32)
    }

    var rotatingAssemblyFrame: CGRect {
        let side = size.width * MaterialMetrics.assemblyWidthMultiplier
        return CGRect(
            x: pivotPoint.x - side / 2,
            y: pivotPoint.y - side / 2,
            width: side,
            height: side
        )
    }

    var pivotBaseFrame: CGRect {
        let width = size.width * MaterialMetrics.pivotBaseWidthMultiplier
        let height = width * MaterialMetrics.pivotBaseAspectRatio
        return CGRect(
            x: pivotPoint.x - width * MaterialMetrics.pivotBaseAnchor.x,
            y: pivotPoint.y - height * MaterialMetrics.pivotBaseAnchor.y,
            width: width,
            height: height
        )
    }

    var stylusPointBeforeRotation: CGPoint {
        let frame = rotatingAssemblyFrame
        return CGPoint(
            x: frame.minX + frame.width * MaterialMetrics.stylusAnchor.x,
            y: frame.minY + frame.height * MaterialMetrics.stylusAnchor.y
        )
    }

    func rotationDegrees(isEngaged: Bool) -> Double {
        // 素材原始朝向已接近停靠位置，播放时向音槽内侧旋转。
        isEngaged ? 24 : 0
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
