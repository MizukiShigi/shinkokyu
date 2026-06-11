import SwiftUI

/// おかえり: ねぎらいの一言と余韻だけ。統計・シェア・評価なし。ボタンは1つ。
struct OkaeriView: View {
    let onClose: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Palette.homeGradBottom, Palette.homeGradTop],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                OkaeriMark()
                    .frame(width: 46, height: 46)

                Text("おつかれさまでした")
                    .font(AppFont.mincho(27))
                    .tracking(4.3)
                    .padding(.leading, 4.3)
                    .foregroundStyle(Palette.sumi)
                    .padding(.top, 36)

                Text("3分間、深呼吸しました")
                    .font(AppFont.gothic(13.5))
                    .tracking(1.6)
                    .padding(.leading, 1.6)
                    .foregroundStyle(Palette.textSub)
                    .padding(.top, 16)

                Button(action: onClose) {
                    Text("とじる")
                        .font(AppFont.gothic(14.5))
                        .tracking(4.35)
                        .padding(.leading, 4.35)
                        .foregroundStyle(Palette.matsu)
                        .frame(width: 138, height: 50)
                        .overlay(
                            Capsule().stroke(Palette.matsu.opacity(0.5), lineWidth: 1)
                        )
                }
                .buttonStyle(SinkButtonStyle())
                .padding(.top, 56)

                Spacer()

                Text("急がず、ひと呼吸してから戻りましょう")
                    .font(AppFont.gothic(11.5))
                    .tracking(1.2)
                    .foregroundStyle(Palette.textSub.opacity(0.8))
                    .padding(.bottom, 32)
            }
        }
    }
}

#Preview {
    OkaeriView(onClose: {})
}
