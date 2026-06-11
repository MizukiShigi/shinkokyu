import Foundation

/// 「今週の森呼吸 n回」のためだけの最小の記録。統計・履歴・ストリークは持たない。
enum WeeklyCounter {

    private static let key = "weeklyCount"

    private static func weekKey(for date: Date = .now) -> String {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = .current
        let week = cal.component(.weekOfYear, from: date)
        let year = cal.component(.yearForWeekOfYear, from: date)
        return "\(year)-W\(week)"
    }

    static var thisWeek: Int {
        guard let dict = UserDefaults.standard.dictionary(forKey: key) as? [String: Int] else { return 0 }
        return dict[weekKey()] ?? 0
    }

    static func increment() {
        // 今週のぶんだけ持ち、過去の週は捨てる
        UserDefaults.standard.set([weekKey(): thisWeek + 1], forKey: key)
    }
}
