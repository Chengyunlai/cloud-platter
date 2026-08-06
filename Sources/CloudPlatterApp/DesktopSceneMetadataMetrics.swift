import AppKit
import CoreGraphics

/// 使用与 SwiftUI 文本一致的系统字体估算信息行宽度，供场景和独立控制 Panel 共享。
enum DesktopSceneMetadataMetrics {
    static func subtitleWidth(text: String, fontSize: CGFloat) -> CGFloat {
        let font = NSFont.systemFont(ofSize: fontSize)
        return ceil((text as NSString).size(withAttributes: [.font: font]).width)
    }
}
