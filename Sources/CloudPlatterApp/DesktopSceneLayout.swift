import CoreGraphics

/// 把全屏尺寸转换为 A 方案的稳定构图，视图只负责在这些区域内绘制。
struct DesktopSceneLayout: Equatable {
    let canvasSize: CGSize

    var metadataFrame: CGRect {
        let originY = canvasSize.height * 0.08
        let preferredBottom = originY + canvasSize.height * 0.26
        let turntableClearance = max(12, canvasSize.height * 0.02)
        let bottom = min(preferredBottom, turntableFrame.minY - turntableClearance)

        return CGRect(
            x: canvasSize.width * 0.07,
            y: originY,
            width: canvasSize.width * 0.82,
            height: max(canvasSize.height * 0.18, bottom - originY)
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

    var playbackControlsFrame: CGRect {
        let height = min(40, max(36, canvasSize.height * 0.044))
        let leadingOffset = min(310, max(250, canvasSize.width * 0.215))
        return CGRect(
            x: metadataFrame.minX + leadingOffset,
            y: metadataFrame.maxY - height,
            width: height * 3.45,
            height: height
        )
    }

    var metadataSubtitleFrame: CGRect {
        let controlsFrame = playbackControlsFrame
        let gap = max(12, canvasSize.width * 0.01)
        return CGRect(
            x: metadataFrame.minX,
            y: controlsFrame.minY,
            width: max(0, controlsFrame.minX - metadataFrame.minX - gap),
            height: controlsFrame.height
        )
    }
}
