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
        let tubeWidth = max(7, size.width * 0.072)

        return ZStack(alignment: .topLeading) {
            counterweight(layout: layout)

            RoundedRectangle(cornerRadius: tubeWidth / 2, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.12), Color(white: 0.5), Color(white: 0.16)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: tubeWidth + 5, height: size.height * 0.15)
                .overlay {
                    RoundedRectangle(cornerRadius: tubeWidth / 2, style: .continuous)
                        .strokeBorder(.white.opacity(0.26), lineWidth: 1)
                }
                .position(
                    x: layout.pivotPoint.x,
                    y: layout.pivotPoint.y + size.height * 0.012
                )

            tonearmTube(layout: layout, tubeWidth: tubeWidth)
            headshell(layout: layout)
        }
        .frame(width: size.width, height: size.height)
    }

    private func counterweight(layout: DesktopSceneTonearmLayout) -> some View {
        let size = layout.size
        let width = size.width * 0.34
        let height = size.height * 0.084

        return ZStack {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(white: 0.13),
                            Color(white: 0.5),
                            Color(white: 0.16),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Rectangle()
                .fill(.black.opacity(0.44))
                .frame(width: max(2, width * 0.07))
                .offset(x: -width * 0.22)

            Rectangle()
                .fill(.white.opacity(0.26))
                .frame(width: 1)
                .offset(x: width * 0.18)
        }
        .frame(width: width, height: height)
        .overlay {
            Capsule().strokeBorder(.black.opacity(0.58), lineWidth: 1)
        }
        .position(
            x: layout.pivotPoint.x,
            y: layout.pivotPoint.y - size.height * 0.095
        )
        .shadow(color: .black.opacity(0.32), radius: 2, x: 2, y: 3)
    }

    private func tonearmTube(layout: DesktopSceneTonearmLayout, tubeWidth: CGFloat) -> some View {
        let size = layout.size
        let tubeFrame = CGSize(width: size.width * 0.38, height: layout.tubeLength)

        return ZStack {
            DesktopSceneTonearmTubeShape()
                .stroke(
                    .black.opacity(0.5),
                    style: StrokeStyle(lineWidth: tubeWidth + 4, lineCap: .round)
                )
                .offset(x: 2, y: 3)
                .blur(radius: 0.7)

            DesktopSceneTonearmTubeShape()
                .stroke(
                    Color(white: 0.12),
                    style: StrokeStyle(lineWidth: tubeWidth + 2.5, lineCap: .round)
                )

            DesktopSceneTonearmTubeShape()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(white: 0.43),
                            Color(white: 0.9),
                            Color(white: 0.48),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: tubeWidth, lineCap: .round)
                )

            DesktopSceneTonearmTubeShape()
                .stroke(
                    .white.opacity(0.48),
                    style: StrokeStyle(lineWidth: 1, lineCap: .round)
                )
                .offset(x: -tubeWidth * 0.2)
        }
        .frame(width: tubeFrame.width, height: tubeFrame.height)
        .position(
            x: layout.pivotPoint.x - size.width * 0.018,
            y: layout.pivotPoint.y + layout.tubeLength / 2
        )
    }

    private func headshell(layout: DesktopSceneTonearmLayout) -> some View {
        let size = layout.size
        let shellWidth = size.width * 0.29
        let shellHeight = size.height * 0.12
        let shellCenter = CGPoint(
            x: layout.tubeEndPoint.x - size.width * 0.01,
            y: layout.tubeEndPoint.y + shellHeight * 0.5
        )
        let cartridgeCenter = CGPoint(
            x: layout.stylusPointBeforeRotation.x,
            y: layout.stylusPointBeforeRotation.y - size.height * 0.044
        )
        let cantileverStart = CGPoint(
            x: cartridgeCenter.x,
            y: cartridgeCenter.y + size.height * 0.028
        )
        let cantileverBend = CGPoint(
            x: layout.stylusPointBeforeRotation.x - size.width * 0.004,
            y: layout.stylusPointBeforeRotation.y - size.height * 0.006
        )

        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: shellWidth * 0.12, style: .continuous)
                .fill(Color.black.opacity(0.36))
                .frame(width: shellWidth * 0.34, height: shellHeight * 0.18)
                .position(x: shellCenter.x, y: shellCenter.y - shellHeight * 0.5)

            DesktopSceneHeadshellShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(white: 0.86),
                            Color(white: 0.52),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay {
                    DesktopSceneHeadshellShape()
                        .stroke(.black.opacity(0.62), lineWidth: 1)
                }
                .frame(width: shellWidth, height: shellHeight)
                .position(x: shellCenter.x, y: shellCenter.y)
                .shadow(color: .black.opacity(0.3), radius: 1.2, x: 1, y: 2)

            headshellPerforations(
                center: shellCenter,
                shellSize: CGSize(width: shellWidth, height: shellHeight)
            )

            ForEach([-1.0, 1.0], id: \.self) { direction in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(white: 0.92), Color(white: 0.36)],
                            center: UnitPoint(x: 0.35, y: 0.28),
                            startRadius: 0,
                            endRadius: shellWidth * 0.08
                        )
                    )
                    .frame(width: shellWidth * 0.1, height: shellWidth * 0.1)
                    .position(
                        x: shellCenter.x + shellWidth * 0.25 * direction,
                        y: shellCenter.y - shellHeight * 0.28
                    )
            }

            cartridge(
                center: cartridgeCenter,
                size: CGSize(width: size.width * 0.16, height: size.height * 0.055)
            )

            let cantileverPath = Path { path in
                path.move(to: cantileverStart)
                path.addLine(to: cantileverBend)
                path.addLine(to: layout.stylusPointBeforeRotation)
            }

            cantileverPath
                .stroke(
                    .black.opacity(0.68),
                    style: StrokeStyle(
                        lineWidth: max(2.6, size.width * 0.02),
                        lineCap: .round
                    )
                )

            cantileverPath.stroke(
                LinearGradient(
                    colors: [Color(white: 0.88), Color(white: 0.62)],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                style: StrokeStyle(
                    lineWidth: max(1.35, size.width * 0.011),
                    lineCap: .round
                )
            )

            Capsule()
                .fill(Color(red: 0.68, green: 0.23, blue: 0.07))
                .overlay {
                    Capsule().stroke(.black.opacity(0.5), lineWidth: 0.6)
                }
                .frame(width: max(4, size.width * 0.034), height: max(2.5, size.width * 0.021))
                .position(cantileverStart)

            Ellipse()
                .fill(.black.opacity(0.42))
                .frame(width: size.width * 0.05, height: max(1.2, size.height * 0.004))
                .position(
                    x: layout.stylusPointBeforeRotation.x + size.width * 0.012,
                    y: layout.stylusPointBeforeRotation.y + size.height * 0.009
                )
                .blur(radius: 0.5)

            DesktopSceneStylusTipShape()
                .fill(Color(white: 0.72))
                .overlay {
                    DesktopSceneStylusTipShape()
                        .stroke(Color(white: 0.08), lineWidth: 0.9)
                }
                .frame(width: max(3.5, size.width * 0.026), height: max(4.5, size.width * 0.033))
                .position(layout.stylusPointBeforeRotation)
        }
        .frame(width: size.width, height: size.height)
    }

    private func headshellPerforations(center: CGPoint, shellSize: CGSize) -> some View {
        ZStack {
            ForEach(0..<15, id: \.self) { index in
                let column = CGFloat(index % 3) - 1
                let row = CGFloat(index / 3) - 2

                Circle()
                    .fill(Color(white: 0.08).opacity(0.88))
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.28), lineWidth: 0.5)
                    }
                    .frame(
                        width: max(1.8, shellSize.width * 0.07),
                        height: max(1.8, shellSize.width * 0.07)
                    )
                    .position(
                        x: center.x + column * shellSize.width * 0.13,
                        y: center.y + row * shellSize.height * 0.12 + shellSize.height * 0.06
                    )
            }
        }
    }

    private func cartridge(center: CGPoint, size: CGSize) -> some View {
        ZStack {
            DesktopSceneCartridgeShape()
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.2), Color(white: 0.08)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Rectangle()
                .fill(Color(red: 0.48, green: 0.22, blue: 0.08))
                .frame(width: size.width * 0.16, height: size.height * 0.72)
                .offset(x: size.width * 0.28)
        }
        .frame(width: size.width, height: size.height)
        .overlay {
            DesktopSceneCartridgeShape()
                .stroke(.white.opacity(0.24), lineWidth: 0.8)
        }
        .position(center)
        .shadow(color: .black.opacity(0.26), radius: 0.8, x: 1, y: 1)
    }

    private func pivotBase(layout: DesktopSceneTonearmLayout) -> some View {
        let size = layout.size
        let diameter = size.width * 0.6

        return ZStack {
            Ellipse()
                .fill(.black.opacity(0.24))
                .frame(width: diameter * 1.08, height: diameter * 0.75)
                .blur(radius: 2)
                .offset(x: 2, y: 4)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.76), Color(white: 0.28), Color(white: 0.62)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    Circle().strokeBorder(Color(white: 0.07), lineWidth: max(2, diameter * 0.055))
                }

            Circle()
                .stroke(
                    Color(red: 0.72, green: 0.51, blue: 0.27).opacity(0.66),
                    lineWidth: max(2, diameter * 0.055)
                )
                .frame(width: diameter * 0.59, height: diameter * 0.59)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.38), Color(white: 0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: diameter * 0.43, height: diameter * 0.43)

            Circle()
                .fill(Color(white: 0.06))
                .frame(width: diameter * 0.13, height: diameter * 0.13)

            Canvas { context, canvasSize in
                for index in 0..<20 {
                    let angle = Double(index) * 2.399
                    let radius = CGFloat((index * 11) % 41) / 100
                    let point = CGPoint(
                        x: canvasSize.width * (0.5 + CGFloat(cos(angle)) * radius),
                        y: canvasSize.height * (0.5 + CGFloat(sin(angle)) * radius)
                    )
                    let grainDiameter = index.isMultiple(of: 3) ? 1.1 : 0.7
                    context.fill(
                        Path(
                            ellipseIn: CGRect(
                                x: point.x,
                                y: point.y,
                                width: grainDiameter,
                                height: grainDiameter
                            )
                        ),
                        with: .color(.white.opacity(index.isMultiple(of: 2) ? 0.045 : 0.025))
                    )
                }
            }
            .frame(width: diameter * 0.78, height: diameter * 0.78)
            .clipShape(Circle())
        }
        .frame(width: diameter, height: diameter)
        .position(layout.pivotPoint)
        .shadow(color: .black.opacity(0.26), radius: 2, x: 2, y: 3)
    }
}

private struct DesktopSceneTonearmTubeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.width * 0.36, y: rect.height * 0.62),
            control1: CGPoint(x: rect.width * 0.69, y: rect.height * 0.2),
            control2: CGPoint(x: rect.width * 0.61, y: rect.height * 0.48)
        )
        path.addCurve(
            to: CGPoint(x: rect.width * 0.42, y: rect.maxY),
            control1: CGPoint(x: rect.width * 0.22, y: rect.height * 0.75),
            control2: CGPoint(x: rect.width * 0.25, y: rect.height * 0.91)
        )
        return path
    }
}

private struct DesktopSceneHeadshellShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width * 0.35, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.width * 0.65, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.width * 0.83, y: rect.maxY * 0.84))
        path.addQuadCurve(
            to: CGPoint(x: rect.width * 0.17, y: rect.maxY * 0.84),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        path.closeSubpath()
        return path
    }
}

private struct DesktopSceneCartridgeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.height * 0.14))
        path.addLine(to: CGPoint(x: rect.width * 0.82, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.width * 0.18, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct DesktopSceneStylusTipShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.height * 0.62))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.height * 0.62))
        path.closeSubpath()
        return path
    }
}
