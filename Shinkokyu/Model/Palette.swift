import SwiftUI

/// デザイン仕様の oklch パレットを sRGB に変換した値。
/// 単一色相(針葉樹の緑)・アクセント色なし。
enum Palette {
    static let sumi    = Color(red: 0.0733, green: 0.1379, blue: 0.1153) // 墨    oklch(.24 .025 170)
    static let shinrin = Color(red: 0.1080, green: 0.2386, blue: 0.1917) // 深林  oklch(.33 .045 168)
    static let matsu   = Color(red: 0.1866, green: 0.3909, blue: 0.3150) // 松    oklch(.46 .065 167) #306450
    static let koke    = Color(red: 0.4063, green: 0.5684, blue: 0.4889) // 苔    oklch(.62 .055 163)
    static let wakaba  = Color(red: 0.6715, green: 0.7728, blue: 0.7139) // 若葉  oklch(.80 .035 160)
    static let kasumi  = Color(red: 0.8896, green: 0.9352, blue: 0.9099) // 霞    oklch(.94 .015 162)
    static let washi   = Color(red: 0.9587, green: 0.9766, blue: 0.9658) // 和紙  oklch(.978 .006 160)

    // 画面ごとの派生色
    static let homeGradTop    = washi
    static let homeGradBottom = Color(red: 0.8767, green: 0.9313, blue: 0.9011) // oklch(.935 .018 162)
    static let splashTop      = shinrin
    static let splashBottom   = Color(red: 0.0392, green: 0.1220, blue: 0.0978) // oklch(.22 .03 172)
    static let scrim          = Color(red: 0.0095, green: 0.0542, blue: 0.0509) // oklch(.15 .02 190)
    static let buttonHi       = Color(red: 0.2155, green: 0.4395, blue: 0.3559) // oklch(.50 .07 167)
    static let buttonLo       = Color(red: 0.1445, green: 0.3326, blue: 0.2669) // oklch(.41 .06 168)
    static let textSub        = Color(red: 0.36, green: 0.43, blue: 0.40)
}

/// 書体システム: 語る言葉=しっぽり明朝 / 機能要素=Zen角ゴシック New
enum AppFont {
    static func mincho(_ size: CGFloat, semiBold: Bool = false) -> Font {
        .custom(semiBold ? "ShipporiMincho-SemiBold" : "ShipporiMincho-Medium", size: size)
    }

    enum GothicWeight: String {
        case light   = "ZenKakuGothicNew-Light"
        case regular = "ZenKakuGothicNew-Regular"
        case medium  = "ZenKakuGothicNew-Medium"
    }

    static func gothic(_ size: CGFloat, weight: GothicWeight = .regular) -> Font {
        .custom(weight.rawValue, size: size)
    }
}
