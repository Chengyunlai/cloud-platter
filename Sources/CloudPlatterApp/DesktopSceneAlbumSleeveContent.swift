import Foundation

/// 汇总封套排版所需内容，并把空闲状态转换为稳定的项目自有唱片文案。
struct DesktopSceneAlbumSleeveContent: Equatable {
    let artworkData: Data?
    let titleText: String
    let artistText: String
    let albumText: String

    init(presentation: DesktopScenePresentation) {
        artworkData = presentation.artworkData
        if presentation.hasDisplayableMedia {
            titleText = presentation.titleText
            artistText = presentation.artistText
            albumText = presentation.albumText
        } else {
            titleText = "CloudPlatter"
            artistText = "等待播放"
            albumText = "桌面唱片场景"
        }
    }
}
