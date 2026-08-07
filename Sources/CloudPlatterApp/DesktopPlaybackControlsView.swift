import CloudPlatterCore
import SwiftUI

struct DesktopPlaybackControlsView: View {
    @ObservedObject var playbackModel: PlaybackModel

    private var isEnabled: Bool {
        playbackModel.canControlPlayback
            && playbackModel.pendingPlaybackControl == nil
    }

    var body: some View {
        GeometryReader { proxy in
            let visualHeight = min(
                proxy.size.height - DesktopPlaybackControlsMetrics.verticalHitPadding * 2,
                DesktopPlaybackControlsMetrics.maximumVisualHeight
            )
            let visualWidth = min(
                proxy.size.width
                    - DesktopPlaybackControlsMetrics.horizontalHitPadding * 2,
                DesktopPlaybackControlsMetrics.visualWidth(visualHeight: visualHeight)
            )

            ZStack {
                Capsule()
                    .fill(.white.opacity(0.14))
                    .frame(width: visualWidth, height: visualHeight)
                Capsule()
                    .stroke(controlBorderColor, lineWidth: 0.75)
                    .frame(width: visualWidth, height: visualHeight)

                HStack(spacing: DesktopPlaybackControlsMetrics.buttonSpacing) {
                    controlButton(
                        command: .previousTrack,
                        symbolName: "backward.end.fill",
                        label: "上一首"
                    )
                    controlButton(
                        command: .togglePlayPause,
                        symbolName: playPauseSymbolName,
                        label: playPauseLabel,
                        isPrimary: true
                    )
                    controlButton(
                        command: .nextTrack,
                        symbolName: "forward.end.fill",
                        label: "下一首"
                    )
                }
                .padding(.horizontal, DesktopPlaybackControlsMetrics.horizontalHitPadding)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .opacity(playbackModel.canControlPlayback ? 1 : 0.5)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("网易云音乐播放控制")
        .accessibilityHint(controlHelpText)
    }

    private func controlButton(
        command: PlaybackControlCommand,
        symbolName: String,
        label: String,
        isPrimary: Bool = false
    ) -> some View {
        Button {
            Task {
                await playbackModel.performPlaybackControl(command)
            }
        } label: {
            Group {
                if playbackModel.pendingPlaybackControl == command {
                    ProgressView()
                        .controlSize(.small)
                        .accessibilityLabel("\(label)处理中")
                } else {
                    Label(label, systemImage: symbolName)
                        .labelStyle(.iconOnly)
                        .font(.system(size: isPrimary ? 14 : 12, weight: .semibold))
                }
            }
        }
        .buttonStyle(DesktopPlaybackControlButtonStyle(isPrimary: isPrimary))
        .disabled(!isEnabled)
        .accessibilityLabel(Text(label))
        .help(buttonHelpText(label: label))
    }

    private var playPauseSymbolName: String {
        playbackModel.nowPlayingState.status == .playing ? "pause.fill" : "play.fill"
    }

    private var playPauseLabel: String {
        playbackModel.nowPlayingState.status == .playing ? "暂停" : "播放"
    }

    private var controlBorderColor: Color {
        playbackModel.playbackControlFailure == nil
            ? .white.opacity(0.22) : .orange.opacity(0.82)
    }

    private var controlHelpText: String {
        switch playbackModel.playbackControlFailure {
        case .none:
            "上一首、播放或暂停、下一首"
        case .unavailable:
            "当前无法连接播放控制，请稍后再试。"
        case .unsupportedSource:
            "当前媒体来源不是网易云音乐。"
        case .commandRejected:
            "网易云音乐没有接受这次播放控制。"
        }
    }

    private func buttonHelpText(label: String) -> String {
        playbackModel.playbackControlFailure == nil ? label : controlHelpText
    }
}

private struct DesktopPlaybackControlButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let isPrimary: Bool

    func makeBody(configuration: Configuration) -> some View {
        let animationPolicy = DesktopPlaybackControlAnimationPolicy(
            isPressed: configuration.isPressed,
            reduceMotion: reduceMotion
        )

        ZStack {
            configuration.label
                .foregroundStyle(.white.opacity(isEnabled ? 0.94 : 0.42))
                .background {
                    Circle()
                        .fill(.white.opacity(buttonOpacity(isPressed: configuration.isPressed)))
                        .frame(
                            width: isPrimary ? 32 : 30,
                            height: isPrimary ? 32 : 30
                        )
                }
                .scaleEffect(animationPolicy.scale)
                .animation(
                    animationPolicy.animationDuration.map(Animation.easeOut(duration:)),
                    value: configuration.isPressed
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
    }

    private func buttonOpacity(isPressed: Bool) -> Double {
        if isPressed {
            return 0.3
        }
        return isPrimary ? 0.2 : 0.08
    }
}

struct DesktopPlaybackControlAnimationPolicy: Equatable {
    let scale: CGFloat
    let animationDuration: Double?

    init(isPressed: Bool, reduceMotion: Bool) {
        scale = isPressed && !reduceMotion ? 0.93 : 1
        animationDuration = reduceMotion ? nil : 0.16
    }
}
