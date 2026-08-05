import AppKit
import CloudPlatterCore
import SwiftUI

struct DesktopSceneView: View {
    let nowPlayingState: NowPlayingState
    let isWindowVisible: Bool
    let isSessionActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var rotationState = RecordRotationState()

    private var presentation: DesktopScenePresentation {
        DesktopScenePresentation(state: nowPlayingState)
    }

    private var animationPolicy: DesktopSceneAnimationPolicy {
        DesktopSceneAnimationPolicy(
            isPlaybackActive: presentation.isRecordSpinning,
            isWindowVisible: isWindowVisible,
            isSessionActive: isSessionActive,
            reduceMotion: reduceMotion
        )
    }

    var body: some View {
        GeometryReader { proxy in
            let layout = DesktopSceneLayout(canvasSize: proxy.size)

            ZStack(alignment: .topLeading) {
                WalnutDesktopBackground()

                metadata(layout: layout)
                    .frame(
                        width: layout.metadataFrame.width,
                        height: layout.metadataFrame.height,
                        alignment: .topLeading
                    )
                    .position(
                        x: layout.metadataFrame.midX,
                        y: layout.metadataFrame.midY
                    )

                AlbumSleeveView(
                    artworkData: presentation.artworkData,
                    usesPlaceholder: presentation.usesPlaceholderArtwork
                )
                .frame(
                    width: layout.sleeveFrame.width,
                    height: layout.sleeveFrame.height
                )
                .rotationEffect(.degrees(-3))
                .position(
                    x: layout.sleeveFrame.midX,
                    y: layout.sleeveFrame.midY
                )

                TurntableView(
                    artworkData: presentation.artworkData,
                    usesPlaceholder: presentation.usesPlaceholderArtwork,
                    isRecordSpinning: presentation.isRecordSpinning,
                    shouldAnimate: animationPolicy.shouldAnimate,
                    reduceMotion: reduceMotion,
                    rotationAngle: rotationAngle
                )
                .frame(
                    width: layout.turntableFrame.width,
                    height: layout.turntableFrame.height
                )
                .position(
                    x: layout.turntableFrame.midX,
                    y: layout.turntableFrame.midY
                )
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("CloudPlatter 全屏动态唱机桌面")
        .onAppear {
            updateRotation(isActive: animationPolicy.shouldAnimate)
        }
        .onChange(of: animationPolicy.shouldAnimate) { _, isActive in
            updateRotation(isActive: isActive)
        }
    }

    private func metadata(layout: DesktopSceneLayout) -> some View {
        VStack(alignment: .leading, spacing: max(8, layout.canvasSize.height * 0.012)) {
            Text("CloudPlatter")
                .font(.system(size: max(12, layout.canvasSize.width * 0.009), weight: .semibold))
                .foregroundStyle(.white.opacity(0.72))

            Text(presentation.titleText)
                .font(
                    .system(
                        size: min(74, max(34, layout.canvasSize.width * 0.043)),
                        weight: .semibold,
                        design: .default
                    )
                )
                .tracking(-1.2)
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.72)

            Text(metadataSubtitle)
                .font(.system(size: min(21, max(14, layout.canvasSize.width * 0.012))))
                .foregroundStyle(.white.opacity(0.76))
                .lineLimit(1)

            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: layout.statusDiameter, height: layout.statusDiameter)
                    .shadow(color: statusColor.opacity(0.65), radius: 3)

                Text(presentation.statusText)
                    .font(.system(size: min(15, max(12, layout.canvasSize.width * 0.009))))
                    .foregroundStyle(.white.opacity(0.82))
            }
            .padding(.top, max(6, layout.canvasSize.height * 0.012))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .shadow(color: .black.opacity(0.34), radius: 2, y: 2)
    }

    private var metadataSubtitle: String {
        guard nowPlayingState.status == .playing || nowPlayingState.status == .paused else {
            return presentation.artistText
        }
        return "\(presentation.artistText) · \(presentation.albumText)"
    }

    private var statusColor: Color {
        presentation.isRecordSpinning
            ? Color(red: 0.83, green: 1, blue: 0.38) : .white.opacity(0.48)
    }

    private func rotationAngle(at date: Date) -> Angle {
        .degrees(rotationState.angle(at: date))
    }

    private func updateRotation(isActive: Bool) {
        let now = Date()
        if isActive {
            rotationState.start(at: now)
        } else {
            withAnimation(.easeOut(duration: 0.35)) {
                rotationState.stop(at: now)
            }
        }
    }
}

private struct WalnutDesktopBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.17, green: 0.055, blue: 0.025),
                    Color(red: 0.43, green: 0.18, blue: 0.085),
                    Color(red: 0.23, green: 0.075, blue: 0.035),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [Color(red: 1, green: 0.78, blue: 0.54).opacity(0.2), .clear],
                center: UnitPoint(x: 0.76, y: 0.08),
                startRadius: 0,
                endRadius: 520
            )

            Canvas { context, size in
                for index in 0..<15 {
                    let progress = CGFloat(index) / 14
                    let y = size.height * (0.06 + progress * 0.9)
                    var path = Path()
                    path.move(to: CGPoint(x: -size.width * 0.05, y: y))
                    path.addCurve(
                        to: CGPoint(x: size.width * 1.05, y: y + size.height * 0.035),
                        control1: CGPoint(x: size.width * 0.22, y: y - size.height * 0.045),
                        control2: CGPoint(x: size.width * 0.68, y: y + size.height * 0.055)
                    )
                    context.stroke(
                        path,
                        with: .color(.white.opacity(index.isMultiple(of: 3) ? 0.04 : 0.018)),
                        lineWidth: index.isMultiple(of: 3) ? 1.2 : 0.7
                    )
                }
            }

            LinearGradient(
                colors: [.white.opacity(0.06), .clear, .black.opacity(0.24)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

private struct AlbumSleeveView: View {
    let artworkData: Data?
    let usesPlaceholder: Bool

    var body: some View {
        GeometryReader { proxy in
            let inset = proxy.size.width * 0.055

            ZStack(alignment: .bottomTrailing) {
                Color(red: 0.85, green: 0.81, blue: 0.72)

                DesktopArtworkSurface(artworkData: artworkData)
                    .padding(.top, inset)
                    .padding(.horizontal, inset)
                    .padding(.bottom, inset * 1.35)

                Text("CLOUDPLATTER · 33⅓ RPM")
                    .font(.system(size: max(6, proxy.size.width * 0.022), weight: .medium))
                    .tracking(1.1)
                    .foregroundStyle(Color.black.opacity(0.58))
                    .padding(.trailing, inset)
                    .padding(.bottom, inset * 0.38)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
        .shadow(color: .black.opacity(0.38), radius: 8, y: 10)
        .accessibilityLabel(usesPlaceholder ? "CloudPlatter 默认封套" : "当前专辑封套")
    }
}

private struct TurntableView: View {
    let artworkData: Data?
    let usesPlaceholder: Bool
    let isRecordSpinning: Bool
    let shouldAnimate: Bool
    let reduceMotion: Bool
    let rotationAngle: (Date) -> Angle

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let recordDiameter = min(size.width * 0.58, size.height * 0.88)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: max(12, size.width * 0.022), style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.91, green: 0.88, blue: 0.81),
                                Color(red: 0.69, green: 0.66, blue: 0.58),
                                Color(red: 0.53, green: 0.5, blue: 0.44),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: max(12, size.width * 0.022),
                            style: .continuous
                        )
                        .strokeBorder(.white.opacity(0.34), lineWidth: 1)
                    }

                TimelineView(
                    .animation(
                        minimumInterval: 1.0 / 30.0,
                        paused: !shouldAnimate
                    )
                ) { context in
                    VinylRecordView(
                        artworkData: artworkData,
                        usesPlaceholder: usesPlaceholder
                    )
                    .frame(width: recordDiameter, height: recordDiameter)
                    .rotationEffect(rotationAngle(context.date))
                }
                .position(x: size.width * 0.35, y: size.height * 0.5)

                TonearmView(isEngaged: isRecordSpinning, reduceMotion: reduceMotion)
                    .frame(width: size.width * 0.16, height: size.height * 0.68)
                    .position(x: size.width * 0.79, y: size.height * 0.42)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.66, green: 0.55, blue: 0.39),
                                Color(red: 0.24, green: 0.2, blue: 0.15),
                            ],
                            center: UnitPoint(x: 0.38, y: 0.3),
                            startRadius: 0,
                            endRadius: size.width * 0.04
                        )
                    )
                    .frame(width: size.width * 0.07, height: size.width * 0.07)
                    .shadow(color: .black.opacity(0.32), radius: 4, y: 4)
                    .position(x: size.width * 0.89, y: size.height * 0.78)

                Text("CLOUD PLATTER")
                    .font(.system(size: max(6, size.width * 0.011), weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(.white.opacity(0.72))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 5)
                    .background(Color(red: 0.26, green: 0.25, blue: 0.23))
                    .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                    .position(x: size.width * 0.9, y: size.height * 0.94)
            }
        }
        .shadow(color: .black.opacity(0.44), radius: 10, y: 16)
        .accessibilityLabel(usesPlaceholder ? "默认唱机" : "使用当前封面的唱机")
    }
}

private struct VinylRecordView: View {
    let artworkData: Data?
    let usesPlaceholder: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            Color.black,
                            Color(white: 0.15),
                            Color(white: 0.035),
                            Color(white: 0.12),
                            Color.black,
                        ],
                        center: .center
                    )
                )

            ForEach([0.62, 0.72, 0.82, 0.91], id: \.self) { scale in
                Circle()
                    .stroke(.white.opacity(0.12), lineWidth: 0.7)
                    .scaleEffect(scale)
            }

            GeometryReader { proxy in
                DesktopArtworkSurface(artworkData: artworkData)
                    .frame(
                        width: proxy.size.width * 0.32,
                        height: proxy.size.width * 0.32
                    )
                    .clipShape(Circle())
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            }

            Circle()
                .fill(.black)
                .frame(width: 8, height: 8)

            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            .clear, .white.opacity(0.14), .clear, .white.opacity(0.05), .clear,
                        ],
                        center: .center
                    )
                )
                .blendMode(.screen)
        }
        .shadow(color: .black.opacity(0.42), radius: 8, y: 9)
        .accessibilityLabel(usesPlaceholder ? "默认唱片" : "使用当前封面的唱片")
    }
}

private struct TonearmView: View {
    let isEngaged: Bool
    let reduceMotion: Bool

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack(alignment: .top) {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.38), Color(white: 0.9), Color(white: 0.44)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(6, size.width * 0.09), height: size.height * 0.76)
                    .offset(y: size.height * 0.12)
                    .shadow(color: .black.opacity(0.28), radius: 3, x: 3, y: 4)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(white: 0.12), Color(white: 0.82), Color(white: 0.3)],
                            center: .center,
                            startRadius: 2,
                            endRadius: size.width * 0.28
                        )
                    )
                    .frame(width: size.width * 0.48, height: size.width * 0.48)
                    .overlay {
                        Circle()
                            .strokeBorder(
                                .black.opacity(0.42), lineWidth: max(2, size.width * 0.07))
                    }

                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white, .gray], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: size.width * 0.23, height: size.height * 0.12)
                    .offset(y: size.height * 0.81)
            }
            .rotationEffect(.degrees(isEngaged ? 17 : 4), anchor: .top)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.35), value: isEngaged)
        }
    }
}

private struct DesktopArtworkSurface: View {
    let artworkData: Data?

    @ViewBuilder
    var body: some View {
        if let artworkData,
            let image = NSImage(data: artworkData)
        {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .scaledToFill()
        } else {
            PlaceholderArtworkView()
        }
    }
}

private struct PlaceholderArtworkView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.15, blue: 0.23),
                    Color(red: 0.72, green: 0.25, blue: 0.29),
                    Color(red: 0.48, green: 0.59, blue: 0.51),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color(red: 1, green: 0.8, blue: 0.34))
                .frame(width: 54, height: 54)
                .offset(x: 42, y: -38)

            Text("夜航")
                .font(.system(size: 32, weight: .semibold, design: .serif))
                .tracking(5)
                .foregroundStyle(.white.opacity(0.94))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(28)
        }
    }
}
