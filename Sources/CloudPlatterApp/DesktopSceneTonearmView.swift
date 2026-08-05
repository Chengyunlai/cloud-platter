import SwiftUI

/// 根据播放状态呈现唱臂抬起或落针的位置。
struct DesktopSceneTonearmView: View {
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
