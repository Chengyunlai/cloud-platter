import CoreGraphics

/// 分离播放控制的视觉尺寸与鼠标命中尺寸：控件保持轻巧，点击区域不低于 44pt。
enum DesktopPlaybackControlsMetrics {
    static let minimumHitSide: CGFloat = 44
    static let buttonSpacing: CGFloat = 2
    static let horizontalHitPadding: CGFloat = 8
    static let verticalHitPadding: CGFloat = 7
    static let maximumVisualHeight: CGFloat = 40

    static func visualHeight(canvasHeight: CGFloat) -> CGFloat {
        min(maximumVisualHeight, max(36, canvasHeight * 0.044))
    }

    static func visualWidth(visualHeight: CGFloat) -> CGFloat {
        visualHeight * 3.45
    }

    static func panelSize(visualSize: CGSize) -> CGSize {
        let minimumWidth =
            minimumHitSide * 3
            + buttonSpacing * 2
            + horizontalHitPadding * 2
        return CGSize(
            width: max(minimumWidth, visualSize.width + horizontalHitPadding * 2),
            height: max(
                minimumHitSide,
                visualSize.height + verticalHitPadding * 2
            )
        )
    }
}
