import Foundation
import WidgetKit

/// 「今週の森呼吸 n回」のためだけの最小の記録。統計・履歴・ストリークは持たない。
/// ウィジェットと共有するため App Group の UserDefaults に保存する。
enum WeeklyCounter {

    /// 実機ではApple Developerアカウント側でこのApp Groupの登録が必要
    /// (Xcode の Signing & Capabilities で Team 設定時に自動登録される)
    static let suiteName = "group.com.shigihara.shinkokyu"
    private static let key = "weeklyCount"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    private static func weekKey(for date: Date = .now) -> String {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = .current
        let week = cal.component(.weekOfYear, from: date)
        let year = cal.component(.yearForWeekOfYear, from: date)
        return "\(year)-W\(week)"
    }

    static var thisWeek: Int {
        guard let dict = defaults.dictionary(forKey: key) as? [String: Int] else { return 0 }
        return dict[weekKey()] ?? 0
    }

    static func increment() {
        // 今週のぶんだけ持ち、過去の週は捨てる
        defaults.set([weekKey(): thisWeek + 1], forKey: key)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
