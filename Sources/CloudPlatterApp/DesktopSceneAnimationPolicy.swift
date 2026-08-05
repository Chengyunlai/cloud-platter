struct DesktopSceneAnimationPolicy: Equatable {
    let isPlaybackActive: Bool
    let isWindowVisible: Bool
    let isSessionActive: Bool
    let reduceMotion: Bool

    var shouldAnimate: Bool {
        isPlaybackActive && isWindowVisible && isSessionActive && !reduceMotion
    }
}
