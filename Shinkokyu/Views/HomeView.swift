import SwiftUI

/// ホーム: ロゴ / 円形ボタン(画面の重心) / 今週の回数。これ以上増やさない。
/// 夜(19-5時)は深林の地に反転する — 寝る前に白い画面で眩しくさせない。
struct HomeView: View {
    let weekCount: Int
    let isNight: Bool
    let onStart: () -> Void

    @State private var pulsing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LinearGradient(
                colors: isNight
                    ? [Palette.splashTop, Palette.splashBottom]
                    : [Palette.homeGradTop, Palette.homeGradBottom],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 9) {
                    RippleMark(color: isNight ? Palette.kasumi : Palette.matsu)
                        .frame(width: 24, height: 24)
                    Text("森呼吸")
                        .font(AppFont.mincho(18, semiBold: true))
                        .tracking(4)
                        .foregroundStyle(isNight ? Palette.kasumi : Palette.sumi)
                }
                .padding(.top, 40)

                Spacer()

                ZStack {
                    // 外輪: 12秒周期(呼吸ループと同じ)で静かに脈動
                    Circle()
                        .stroke(
                            (isNight ? Palette.koke : Palette.wakaba).opacity(0.9),
                            lineWidth: 1
                        )
                        .frame(width: 294, height: 294)
                        .scaleEffect(pulsing ? 1.05 : 1.0)
                        .opacity(pulsing ? 0.25 : 0.55)
                    Circle()
                        .stroke(Palette.koke.opacity(0.35), lineWidth: 1)
                        .frame(width: 262, height: 262)

                    Button(action: onStart) {
                        ZStack {
                            Circle()
                                .fill(RadialGradient(
                                    colors: [Palette.buttonHi, Palette.buttonLo],
                                    center: UnitPoint(x: 0.5, y: 0.34),
                                    startRadius: 0, endRadius: 180
                                ))
                            VStack(spacing: 11) {
                                Text("はじめる")
                                    .font(AppFont.gothic(24, weight: .medium))
                                    .tracking(4.8)
                                    .padding(.leading, 4.8)
                                Text("3分")
                                    .font(AppFont.gothic(13))
                                    .tracking(2.6)
                                    .padding(.leading, 2.6)
                                    .opacity(0.72)
                            }
                            .foregroundStyle(Palette.washi)
                        }
                        .frame(width: 230, height: 230)
                        .shadow(
                            color: isNight
                                ? Palette.splashBottom.opacity(0.6)
                                : Palette.matsu.opacity(0.30),
                            radius: 28, x: 0, y: 14
                        )
                    }
                    .buttonStyle(SinkButtonStyle())
                }

                Spacer()

                Text("今週の森呼吸 \(weekCount)回")
                    .font(AppFont.gothic(12.5))
                    .tracking(1.75)
                    .foregroundStyle(isNight ? Palette.wakaba.opacity(0.85) : Palette.textSub)
                    .padding(.bottom, 32)
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                pulsing = true
            }
        }
    }
}

/// ボタン沈み 0.4s (スライド・バウンス禁止)
struct SinkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.4), value: configuration.isPressed)
    }
}

#Preview("昼") {
    HomeView(weekCount: 2, isNight: false, onStart: {})
}

#Preview("夜") {
    HomeView(weekCount: 2, isNight: true, onStart: {})
}
