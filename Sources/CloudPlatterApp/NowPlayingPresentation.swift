import CloudPlatterCore

struct NowPlayingPresentation: Equatable {
    enum StatusTone: Equatable {
        case neutral
        case positive
        case caution
        case negative
    }

    let statusTone: StatusTone
    let statusText: String
    let menuBarTitle: String
    let titleText: String
    let artistText: String
    let albumText: String
    let guidanceText: String
    let symbolName: String
    let showsMetadata: Bool
}

extension NowPlayingPresentation {
    init(state: NowPlayingState) {
        switch state.status {
        case .idle:
            self = Self(
                statusTone: .neutral,
                statusText: "等待播放",
                menuBarTitle: "等待播放",
                titleText: "还没有正在播放的内容",
                artistText: "",
                albumText: "",
                guidanceText: "在网易云音乐中播放一首歌曲，这里会自动更新。",
                symbolName: "record.circle",
                showsMetadata: false
            )
        case .playing:
            self = Self.playback(
                state: state,
                statusTone: .positive,
                statusText: "正在播放",
                guidanceText: "播放信息来自这台 Mac 上的网易云音乐。",
                symbolName: "play.circle.fill"
            )
        case .paused:
            self = Self.playback(
                state: state,
                statusTone: .caution,
                statusText: "已暂停",
                guidanceText: "继续播放后，唱片会再次随音乐转动。",
                symbolName: "pause.circle.fill"
            )
        case .unavailable:
            self = Self(
                statusTone: .negative,
                statusText: "暂时无法读取",
                menuBarTitle: "暂时无法读取",
                titleText: "无法读取播放状态",
                artistText: "",
                albumText: "",
                guidanceText: "当前系统与此版本暂不兼容，你仍可正常使用网易云音乐。",
                symbolName: "exclamationmark.circle",
                showsMetadata: false
            )
        }
    }

    private static func playback(
        state: NowPlayingState,
        statusTone: StatusTone,
        statusText: String,
        guidanceText: String,
        symbolName: String
    ) -> Self {
        let title = state.title.nonEmpty ?? "当前曲目"
        return Self(
            statusTone: statusTone,
            statusText: statusText,
            menuBarTitle: title,
            titleText: title,
            artistText: state.artist.nonEmpty ?? "未知艺人",
            albumText: state.album.nonEmpty ?? "未知专辑",
            guidanceText: guidanceText,
            symbolName: symbolName,
            showsMetadata: true
        )
    }
}
