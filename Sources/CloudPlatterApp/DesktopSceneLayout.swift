import CoreGraphics

/// 把全屏尺寸转换为 A 方案的稳定构图，视图只负责在这些区域内绘制。
struct DesktopSceneLayout: Equatable {
    let canvasSize: CGSize
    let metadataSubtitleWidth: CGFloat
    let measuredMetadataTitleHeight: CGFloat

    init(
        canvasSize: CGSize,
        metadataSubtitleWidth: CGFloat = 0,
        measuredMetadataTitleHeight: CGFloat = 0
    ) {
        self.canvasSize = canvasSize
        self.metadataSubtitleWidth = metadataSubtitleWidth
        self.measuredMetadataTitleHeight = measuredMetadataTitleHeight
    }

    init(canvasSize: CGSize, titleText: String, subtitleText: String) {
        let baseLayout = DesktopSceneLayout(canvasSize: canvasSize)
        self.init(
            canvasSize: canvasSize,
            metadataSubtitleWidth: DesktopSceneMetadataMetrics.subtitleWidth(
                text: subtitleText,
                fontSize: baseLayout.metadataSubtitleFontSize
            ),
            measuredMetadataTitleHeight: DesktopSceneMetadataMetrics.titleHeight(
                text: titleText,
                fontSize: baseLayout.metadataTitleFontSize,
                maximumWidth: baseLayout.metadataFrame.width
            )
        )
    }

    var metadataFrame: CGRect {
        let originY = canvasSize.height * 0.08
        let preferredBottom = originY + canvasSize.height * 0.26
        let turntableClearance = max(6, canvasSize.height * 0.008)
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

    var playbackControlsVisualFrame: CGRect {
        let height = DesktopPlaybackControlsMetrics.visualHeight(
            canvasHeight: canvasSize.height
        )
        let width = DesktopPlaybackControlsMetrics.visualWidth(visualHeight: height)
        let gap = metadataControlGap
        let maximumSubtitleWidth = max(
            160,
            metadataFrame.width - width - gap
        )
        let allocatedSubtitleWidth = min(
            max(160, metadataSubtitleWidth),
            maximumSubtitleWidth
        )
        return CGRect(
            x: metadataFrame.minX + allocatedSubtitleWidth + gap,
            y: min(metadataFrame.maxY - height, metadataInformationRowMinY),
            width: width,
            height: height
        )
    }

    /// 独立控制 Panel 比可见胶囊稍大，使三个按钮都有至少 44pt 的命中区域。
    var playbackControlsFrame: CGRect {
        let visualFrame = playbackControlsVisualFrame
        let panelSize = DesktopPlaybackControlsMetrics.panelSize(
            visualSize: visualFrame.size
        )
        return CGRect(
            x: visualFrame.midX - panelSize.width / 2,
            y: visualFrame.midY - panelSize.height / 2,
            width: panelSize.width,
            height: panelSize.height
        )
    }

    var metadataSubtitleFrame: CGRect {
        let controlsFrame = playbackControlsVisualFrame
        return CGRect(
            x: metadataFrame.minX,
            y: controlsFrame.minY,
            width: max(0, controlsFrame.minX - metadataFrame.minX - metadataControlGap),
            height: controlsFrame.height
        )
    }

    var metadataBrandFrame: CGRect {
        CGRect(
            x: metadataFrame.minX,
            y: metadataFrame.minY,
            width: metadataFrame.width,
            height: ceil(metadataBrandFontSize * 1.2)
        )
    }

    var metadataTitleFrame: CGRect {
        let originY = metadataBrandFrame.maxY + metadataVerticalSpacing
        return CGRect(
            x: metadataFrame.minX,
            y: originY,
            width: metadataFrame.width,
            height: max(0, metadataSubtitleFrame.minY - metadataVerticalSpacing - originY)
        )
    }

    var metadataVerticalSpacing: CGFloat {
        min(7, max(5, canvasSize.height * 0.007))
    }

    var metadataBrandFontSize: CGFloat {
        min(14, max(12, canvasSize.width * 0.009))
    }

    var metadataTitleFontSize: CGFloat {
        min(
            74,
            max(34, min(canvasSize.width * 0.043, canvasSize.height * 0.081))
        )
    }

    var metadataSubtitleFontSize: CGFloat {
        min(21, max(14, canvasSize.width * 0.012))
    }

    private var metadataInformationRowMinY: CGFloat {
        let defaultTitleHeight = ceil(metadataTitleFontSize * 1.2)
        let titleHeight = max(defaultTitleHeight, measuredMetadataTitleHeight)
        return metadataFrame.minY
            + metadataBrandFrame.height
            + titleHeight
            + metadataVerticalSpacing * 2
    }

    private var metadataControlGap: CGFloat {
        max(12, canvasSize.width * 0.01)
    }
}
