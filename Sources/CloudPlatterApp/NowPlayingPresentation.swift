import CloudPlatterCore

struct NowPlayingPresentation: Equatable {
    enum Kind: Equatable {
        case idle
        case playing
        case paused
        case unavailable
    }

    let kind: Kind
    let statusText: String
    let menuBarTitle: String
    let titleText: String
    let artistText: String
    let albumText: String
    let guidanceText: String
    let symbolName: String
    let showsMetadata: Bool

    init(state: NowPlayingState) {
        switch state.status {
        case .idle:
            kind = .idle
            statusText = "等待播放"
            menuBarTitle = "等待播放"
            titleText = "还没有正在播放的内容"
            artistText = ""
            albumText = ""
            guidanceText = "在网易云音乐中播放一首歌曲，这里会自动更新。"
            symbolName = "record.circle"
            showsMetadata = false
        case .playing:
            kind = .playing
            statusText = "正在播放"
            titleText = state.title.nonEmpty ?? "当前曲目"
            menuBarTitle = titleText
            artistText = state.artist.nonEmpty ?? "未知艺人"
            albumText = state.album.nonEmpty ?? "未知专辑"
            guidanceText = "播放信息来自这台 Mac 上的网易云音乐。"
            symbolName = "play.circle.fill"
            showsMetadata = true
        case .paused:
            kind = .paused
            statusText = "已暂停"
            titleText = state.title.nonEmpty ?? "当前曲目"
            menuBarTitle = titleText
            artistText = state.artist.nonEmpty ?? "未知艺人"
            albumText = state.album.nonEmpty ?? "未知专辑"
            guidanceText = "继续播放后，唱片会再次随音乐转动。"
            symbolName = "pause.circle.fill"
            showsMetadata = true
        case .unavailable:
            kind = .unavailable
            statusText = "暂时无法读取"
            menuBarTitle = "暂时无法读取"
            titleText = "无法读取播放状态"
            artistText = ""
            albumText = ""
            guidanceText = "当前系统与此版本暂不兼容，你仍可正常使用网易云音乐。"
            symbolName = "exclamationmark.circle"
            showsMetadata = false
        }
    }
}

extension Optional where Wrapped == String {
    fileprivate var nonEmpty: String? {
        guard let value = self?.trimmingCharacters(in: .whitespacesAndNewlines),
            !value.isEmpty
        else {
            return nil
        }
        return value
    }
}
