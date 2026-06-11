import Foundation

/// 1景 = 写真 + 場所名 + 現地の一言 + 環境音
struct ForestScene: Identifiable, Equatable {
    enum TimeBucket { case day, dusk, night }

    let id: String
    let photoName: String   // Resources/Photos/*.heic (拡張子なし)
    let place: String
    let info: String
    let soundName: String   // Resources/Sounds/*.m4a (拡張子なし)
    let bucket: TimeBucket
}

/// 選択肢ゼロ: ユーザーは選ばない。時刻と日付からアプリが1景を決める。
enum SceneCatalog {

    static let all: [ForestScene] = [
        // ---- 昼 ----
        .init(id: "kegon", photoName: "photo-kegon-falls", place: "栃木・華厳の滝",
              info: "夏空・水のとどろき", soundName: "ambient-river-falls", bucket: .day),
        .init(id: "bamboo", photoName: "photo-arashiyama-bamboo", place: "京都・嵐山 竹林の小径",
              info: "朝の光・竹の葉ずれ", soundName: "ambient-forest-afternoon", bucket: .day),
        .init(id: "hozugawa", photoName: "photo-hozugawa", place: "京都・嵐山 保津川",
              info: "新緑・川面の風", soundName: "ambient-stream-gentle", bucket: .day),
        .init(id: "daigoji", photoName: "photo-daigoji", place: "京都・醍醐寺",
              info: "新緑の池庭", soundName: "ambient-birds-spring", bucket: .day),
        .init(id: "garden", photoName: "photo-garden-falls", place: "苔の庭",
              info: "雨上がり・小さな滝", soundName: "ambient-stream-close", bucket: .day),
        .init(id: "senjojiki", photoName: "photo-senjojiki", place: "長野・千畳敷カール",
              info: "高山の風", soundName: "ambient-birds-spring", bucket: .day),
        .init(id: "cedar", photoName: "photo-cedar-forest", place: "杉の森",
              info: "しっとりした空気", soundName: "ambient-forest-afternoon", bucket: .day),
        .init(id: "biei", photoName: "photo-biei", place: "北海道・美瑛 青い池",
              info: "静かな水面", soundName: "ambient-birds-spring", bucket: .day),
        .init(id: "azusagawa", photoName: "photo-azusagawa", place: "長野・上高地 梓川",
              info: "澄んだ流れ・秋", soundName: "ambient-stream-gentle", bucket: .day),
        // ---- 夕 ----
        .init(id: "nachi", photoName: "photo-nachi-falls", place: "和歌山・那智の滝",
              info: "夕方の光・滝音", soundName: "ambient-river-falls", bucket: .dusk),
        .init(id: "komagane", photoName: "photo-komagane", place: "長野・駒ヶ根",
              info: "紅葉並木・長い影", soundName: "ambient-birds-evening", bucket: .dusk),
        .init(id: "ashinoko", photoName: "photo-ashinoko", place: "神奈川・箱根 芦ノ湖",
              info: "夕雲・湖の鳥居", soundName: "ambient-birds-evening", bucket: .dusk),
        // ---- 夜 ----
        .init(id: "starry", photoName: "photo-starry-forest", place: "星の森",
              info: "夜・梢の星空", soundName: "ambient-crickets-night", bucket: .night),
        .init(id: "fuji", photoName: "photo-fuji-night", place: "富士山・湖畔",
              info: "星月夜", soundName: "ambient-birds-evening", bucket: .night),
    ]

    /// セッション中の写真ローテーション: 同じ時間帯の景を、起点の景から順に巡る
    static func rotation(startingAt scene: ForestScene) -> [ForestScene] {
        let bucket = all.filter { $0.bucket == scene.bucket }
        guard let i = bucket.firstIndex(of: scene) else { return [scene] }
        return Array(bucket[i...]) + Array(bucket[..<i])
    }

    /// 現在の時間帯。ホームのダーク地切替にも使う。
    /// デバッグ/スクリーンショット用に -forceBucket day|dusk|night で固定可能。
    static func bucket(for date: Date = Date()) -> ForestScene.TimeBucket {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-forceBucket"), i + 1 < args.count {
            switch args[i + 1] {
            case "day":   return .day
            case "dusk":  return .dusk
            case "night": return .night
            default: break
            }
        }
        switch Calendar.current.component(.hour, from: date) {
        case 5..<15:  return .day
        case 15..<19: return .dusk
        default:      return .night
        }
    }

    static func current(date: Date = Date()) -> ForestScene {
        // デバッグ/スクリーンショット用: -sceneID <id> で景を固定
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-sceneID"), i + 1 < args.count,
           let forced = all.first(where: { $0.id == args[i + 1] }) {
            return forced
        }
        let candidates = all.filter { $0.bucket == bucket(for: date) }
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 0
        return candidates[dayOfYear % candidates.count]
    }
}
