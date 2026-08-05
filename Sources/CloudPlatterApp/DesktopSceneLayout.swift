import CoreGraphics

/// 把全屏尺寸转换为 A 方案的稳定构图，视图只负责在这些区域内绘制。
struct DesktopSceneLayout: Equatable {
    let canvasSize: CGSize

    var metadataFrame: CGRect {
        CGRect(
            x: canvasSize.width * 0.07,
            y: canvasSize.height * 0.08,
            width: canvasSize.width * 0.4,
            height: canvasSize.height * 0.26
        )
    }

    var sleeveFrame: CGRect {
        let width = min(canvasSize.width * 0.31, canvasSize.height * 0.5)
        return CGRect(
            x: canvasSize.width * 0.07,
            y: canvasSize.height - canvasSize.height * 0.07 - width,
            width: width,
            height: width
        )
    }

    var turntableFrame: CGRect {
        let width = min(canvasSize.width * 0.56, canvasSize.height * 0.9)
        let height = width / 1.55
        return CGRect(
            x: canvasSize.width - canvasSize.width * 0.05 - width,
            y: canvasSize.height - canvasSize.height * 0.09 - height,
            width: width,
            height: height
        )
    }

    var statusDiameter: CGFloat {
        max(6, min(10, canvasSize.width * 0.006))
    }
}
