import SwiftUI

/// 根据播放状态呈现唱臂抬起或落针的位置。
struct DesktopSceneTonearmView: View {
    let isEngaged: Bool
    let reduceMotion: Bool

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let layout = DesktopSceneTonearmLayout(size: size)

            ZStack(alignment: .topLeading) {
                armAssembly(layout: layout)
                    .rotationEffect(
                        .degrees(layout.rotationDegrees(isEngaged: isEngaged)),
                        anchor: UnitPoint(
                            x: layout.pivotPoint.x / size.width,
                            y: layout.pivotPoint.y / size.height
                        )
                    )

                pivotBase(layout: layout)
            }
            .frame(width: size.width, height: size.height)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.45), value: isEngaged)
        }
    }

    private func armAssembly(layout: DesktopSceneTonearmLayout) -> some View {
        let size = layout.size
        let tubeWidth = max(7, size.width * 0.075)

        return ZStack(alignment: .topLeading) {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.12), Color(white: 0.38), Color(white: 0.1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: size.width * 0.32, height: size.height * 0.075)
                .overlay {
                    Capsule()
                        .strokeBorder(.white.opacity(0.18), lineWidth: 1)
                }
                .position(
                    x: layout.pivotPoint.x,
                    y: layout.pivotPoint.y - size.height * 0.085
                )
                .shadow(color: .black.opacity(0.38), radius: 3, x: 2, y: 3)

            RoundedRectangle(cornerRadius: tubeWidth / 2, style: .continuous)
                .fill(Color(white: 0.2))
                .frame(width: tubeWidth + 3, height: size.height * 0.14)
                .position(
                    x: layout.pivotPoint.x,
                    y: layout.pivotPoint.y - size.height * 0.015
                )

            tonearmTube(layout: layout, tubeWidth: tubeWidth)
            headshell(layout: layout)
        }
        .frame(width: size.width, height: size.height)
    }

    private func tonearmTube(layout: DesktopSceneTonearmLayout, tubeWidth: CGFloat) -> some View {
        let size = layout.size
        let tubeFrame = CGSize(width: size.width * 0.28, height: layout.tubeLength)

        return ZStack {
            DesktopSceneTonearmTubeShape()
                .stroke(
                    .black.opacity(0.42),
                    style: StrokeStyle(lineWidth: tubeWidth + 4, lineCap: .round)
                )
                .offset(x: 3, y: 4)
                .blur(radius: 1.2)

            DesktopSceneTonearmTubeShape()
                .stroke(
                    Color(white: 0.16),
                    style: StrokeStyle(lineWidth: tubeWidth + 2, lineCap: .round)
                )

            DesktopSceneTonearmTubeShape()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(white: 0.32),
                            Color(white: 0.9),
                            Color(white: 0.56),
                            Color(white: 0.2),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: tubeWidth, lineCap: .round)
                )

            DesktopSceneTonearmTubeShape()
                .stroke(
                    .white.opacity(0.42),
                    style: StrokeStyle(lineWidth: 1.1, lineCap: .round)
                )
                .offset(x: -tubeWidth * 0.18)
        }
        .frame(width: tubeFrame.width, height: tubeFrame.height)
        .position(
            x: layout.pivotPoint.x - size.width * 0.018,
            y: layout.pivotPoint.y + layout.tubeLength / 2
        )
    }

    private func headshell(layout: DesktopSceneTonearmLayout) -> some View {
        let size = layout.size
        let shellWidth = size.width * 0.28
        let shellHeight = size.height * 0.115
        let shellCenter = CGPoint(
            x: layout.tubeEndPoint.x - size.width * 0.012,
            y: layout.tubeEndPoint.y + shellHeight * 0.52
        )

        return ZStack(alignment: .topLeading) {
            DesktopSceneHeadshellShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(white: 0.13),
                            Color(white: 0.38),
                            Color(white: 0.16),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay {
                    DesktopSceneHeadshellShape()
                        .stroke(.white.opacity(0.28), lineWidth: 1)
                }
                .frame(width: shellWidth, height: shellHeight)
                .position(x: shellCenter.x, y: shellCenter.y)
                .shadow(color: .black.opacity(0.36), radius: 2, x: 2, y: 3)

            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.46, green: 0.34, blue: 0.2),
                            Color(white: 0.12),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: size.width * 0.13, height: size.height * 0.047)
                .position(
                    x: layout.stylusPointBeforeRotation.x,
                    y: layout.pivotPoint.y + size.height * 0.655
                )

            Path { path in
                path.move(
                    to: CGPoint(
                        x: layout.stylusPointBeforeRotation.x,
                        y: layout.pivotPoint.y + size.height * 0.67
                    )
                )
                path.addLine(to: layout.stylusPointBeforeRotation)
            }
            .stroke(
                Color(red: 0.18, green: 0.13, blue: 0.09),
                style: StrokeStyle(lineWidth: max(1.2, size.width * 0.012), lineCap: .round)
            )

            Circle()
                .fill(Color(red: 0.62, green: 0.45, blue: 0.24))
                .frame(width: max(3, size.width * 0.028), height: max(3, size.width * 0.028))
                .position(layout.stylusPointBeforeRotation)
        }
        .frame(width: size.width, height: size.height)
    }

    private func pivotBase(layout: DesktopSceneTonearmLayout) -> some View {
        let size = layout.size
        let diameter = size.width * 0.58

        return ZStack {
            Circle()
                .fill(.black.opacity(0.22))
                .frame(width: diameter * 1.06, height: diameter * 0.72)
                .blur(radius: 3)
                .offset(x: 3, y: 6)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(white: 0.5), Color(white: 0.14)],
                        center: UnitPoint(x: 0.36, y: 0.28),
                        startRadius: 1,
                        endRadius: diameter * 0.56
                    )
                )
                .overlay {
                    Circle().strokeBorder(.black.opacity(0.5), lineWidth: max(2, diameter * 0.055))
                }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(white: 0.72), Color(white: 0.24), Color(white: 0.08)],
                        center: UnitPoint(x: 0.34, y: 0.28),
                        startRadius: 0,
                        endRadius: diameter * 0.3
                    )
                )
                .frame(width: diameter * 0.48, height: diameter * 0.48)

            Circle()
                .fill(.black.opacity(0.76))
                .frame(width: diameter * 0.14, height: diameter * 0.14)

            Circle()
                .fill(.white.opacity(0.72))
                .frame(width: diameter * 0.08, height: diameter * 0.08)
                .offset(x: -diameter * 0.13, y: -diameter * 0.14)
                .blur(radius: 0.6)
        }
        .frame(width: diameter, height: diameter)
        .position(layout.pivotPoint)
        .shadow(color: .black.opacity(0.34), radius: 4, x: 2, y: 4)
    }
}

private struct DesktopSceneTonearmTubeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.midX - rect.width * 0.12, y: rect.maxY),
            control1: CGPoint(x: rect.midX + rect.width * 0.11, y: rect.height * 0.3),
            control2: CGPoint(x: rect.midX - rect.width * 0.12, y: rect.height * 0.72)
        )
        return path
    }
}

private struct DesktopSceneHeadshellShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width * 0.35, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.width * 0.65, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.width * 0.78, y: rect.maxY * 0.84))
        path.addQuadCurve(
            to: CGPoint(x: rect.width * 0.22, y: rect.maxY * 0.84),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        path.closeSubpath()
        return path
    }
}
