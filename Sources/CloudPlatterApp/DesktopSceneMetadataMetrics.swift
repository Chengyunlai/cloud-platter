import AppKit
import CoreGraphics

/// 使用与 SwiftUI 文本一致的系统字体估算标题高度与信息行宽度，供场景和独立控制 Panel 共享。
enum DesktopSceneMetadataMetrics {
    static func subtitleWidth(text: String, fontSize: CGFloat) -> CGFloat {
        let font = NSFont.systemFont(ofSize: fontSize)
        return ceil((text as NSString).size(withAttributes: [.font: font]).width)
    }

    static func titleHeight(text: String, fontSize: CGFloat, maximumWidth: CGFloat) -> CGFloat {
        let font = NSFont.systemFont(ofSize: fontSize, weight: .semibold)
        let lineHeight = ceil(font.boundingRectForFont.height)
        let bounds = (text as NSString).boundingRect(
            with: CGSize(width: maximumWidth, height: lineHeight * 2),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font]
        )
        return min(lineHeight * 2, max(lineHeight, ceil(bounds.height)))
    }
}
