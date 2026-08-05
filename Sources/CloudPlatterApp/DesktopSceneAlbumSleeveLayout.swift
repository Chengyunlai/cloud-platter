import CoreGraphics

/// 根据封套尺寸、原始封面像素和显示缩放确定印刷区域，限制低分辨率图片的放大倍数。
struct DesktopSceneAlbumSleeveLayout: Equatable {
    let artworkPlateSide: CGFloat
    let artworkSide: CGFloat

    init(
        sleeveSize: CGSize,
        artworkPixelSize: CGSize?,
        displayScale: CGFloat
    ) {
        let maximumSide = min(sleeveSize.width * 0.48, sleeveSize.height * 0.48)
        artworkPlateSide = maximumSide
        guard let artworkPixelSize else {
            artworkSide = maximumSide
            return
        }

        let pixelSide = min(artworkPixelSize.width, artworkPixelSize.height)
        let nativePointSide = pixelSide / max(displayScale, 1)
        artworkSide = min(maximumSide, max(nativePointSide, 0))
    }
}
