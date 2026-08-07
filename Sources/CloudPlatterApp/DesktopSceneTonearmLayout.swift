import CoreGraphics

/// 统一唱臂各部件的比例和落针轨迹，避免视觉绘制与命中位置各自计算。
struct DesktopSceneTonearmLayout: Equatable {
    let size: CGSize

    // 完整唱臂素材扩展为 1500×1500 透明画布，机械轴心固定在画布中心。
    private enum MaterialMetrics {
        static let assemblyWidthMultiplier: CGFloat = 3.1
        static let assemblyAspectRatio: CGFloat = 1
        static let pivotAnchor = CGPoint(x: 0.5, y: 0.5)
        static let stylusAnchor = CGPoint(
            x: CGFloat(259) / 1500,
            y: CGFloat(1392) / 1500
        )

        // 固定底座素材裁切尺寸为 440×552，中心圆盘是唱臂的静态轴座。
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

    var tubeLength: CGFloat {
        size.height * 0.52
    }

    var rotatingAssemblyFrame: CGRect {
        let width = size.width * MaterialMetrics.assemblyWidthMultiplier
        let height = width * MaterialMetrics.assemblyAspectRatio
        return frame(
            width: width,
            height: height,
            anchor: MaterialMetrics.pivotAnchor
        )
    }

    var pivotBaseFrame: CGRect {
        let width = size.width * MaterialMetrics.pivotBaseWidthMultiplier
        let height = width * MaterialMetrics.pivotBaseAspectRatio
        return frame(
            width: width,
            height: height,
            anchor: MaterialMetrics.pivotBaseAnchor
        )
    }

    var tubeEndPoint: CGPoint {
        CGPoint(
            x: pivotPoint.x - size.width * 0.035,
            y: pivotPoint.y + tubeLength
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
        // 新素材出厂时已经朝左下，播放时只需小角度压向音槽。
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

    private func frame(width: CGFloat, height: CGFloat, anchor: CGPoint) -> CGRect {
        CGRect(
            x: pivotPoint.x - width * anchor.x,
            y: pivotPoint.y - height * anchor.y,
            width: width,
            height: height
        )
    }
}
