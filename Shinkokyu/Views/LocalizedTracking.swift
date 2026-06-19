import SwiftUI

extension View {
    /// 字間。日本語は指定どおりの余白を、それ以外の言語(英語など)は
    /// レターが離れて読みにくくならないよう控えめにする。
    /// ブランド表記(森呼吸/しんこきゅう)は常に日本語なので従来の .tracking を使う。
    func bodyTracking(_ amount: CGFloat) -> some View {
        let isJapanese = Locale.current.language.languageCode?.identifier == "ja"
        return tracking(isJapanese ? amount : 0)
    }
}
