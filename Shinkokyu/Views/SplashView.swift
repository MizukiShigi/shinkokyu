import SwiftUI

/// スプラッシュ: 深林の地 + 反転ロゴ。1.2秒滞在 → 0.8秒フェードでホームへ。
struct SplashView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Palette.splashTop, Palette.splashBottom],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                RippleMark(color: Palette.kasumi)
                    .frame(width: 104, height: 104)
                Text("森呼吸")
                    .font(AppFont.mincho(25, semiBold: true))
                    .tracking(7.5)
                    .padding(.leading, 7.5)
                    .foregroundStyle(Palette.kasumi)
                    .padding(.top, 30)
                Text("しんこきゅう")
                    .font(AppFont.gothic(10))
                    .tracking(5.2)
                    .padding(.leading, 5.2)
                    .foregroundStyle(Palette.wakaba)
                    .padding(.top, 14)
            }
        }
    }
}

#Preview { SplashView() }
