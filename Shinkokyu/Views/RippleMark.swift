import SwiftUI

/// ロゴ B-2「めぐる波紋」。
/// 一本の木の樹冠が呼吸の波紋になる。波紋は下で開き、幹が中心を通って地面へ届く。
/// 96×96 のデザイン座標系をそのままスケールして描画する。
struct RippleMark: View {
    var color: Color = Palette.matsu

    var body: some View {
        GeometryReader { geo in
            let u = min(geo.size.width, geo.size.height) / 96
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 15 * u, height: 15 * u)
                    .position(x: 48 * u, y: 36 * u)
                ripple(radius: 17, lineWidth: 3.2, u: u)
                ripple(radius: 27, lineWidth: 1.7, u: u)
                Path { p in
                    p.move(to: CGPoint(x: 48 * u, y: 47 * u))
                    p.addLine(to: CGPoint(x: 48 * u, y: 88 * u))
                }
                .stroke(color, style: StrokeStyle(lineWidth: 5 * u, lineCap: .round))
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    /// SVG の stroke-dasharray "18 14 68" 相当。
    /// 円周の14%の切れ目が真下(幹の通り道)に来るよう回転させる。
    private func ripple(radius: CGFloat, lineWidth: CGFloat, u: CGFloat) -> some View {
        Circle()
            .trim(from: 0.14, to: 1.0)
            .rotation(.degrees(64.8))
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth * u, lineCap: .round))
            .frame(width: radius * 2 * u, height: radius * 2 * u)
            .position(x: 48 * u, y: 36 * u)
    }
}

/// おかえり画面の余韻マーク(切れ目のない三重円)
struct OkaeriMark: View {
    var color: Color = Palette.koke

    var body: some View {
        GeometryReader { geo in
            let u = min(geo.size.width, geo.size.height) / 96
            ZStack {
                Circle().fill(color)
                    .frame(width: 16 * u, height: 16 * u)
                Circle().stroke(color, lineWidth: 2.4 * u)
                    .frame(width: 40 * u, height: 40 * u)
                Circle().stroke(color, lineWidth: 1.2 * u)
                    .frame(width: 64 * u, height: 64 * u)
            }
            .position(x: 48 * u, y: 48 * u)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    VStack(spacing: 40) {
        RippleMark().frame(width: 132, height: 132)
        OkaeriMark().frame(width: 46, height: 46)
    }
}
