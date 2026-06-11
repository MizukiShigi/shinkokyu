import WidgetKit
import SwiftUI

// MARK: - データ

struct WeekEntry: TimelineEntry {
    let date: Date
    let count: Int
}

struct WeekProvider: TimelineProvider {

    func placeholder(in context: Context) -> WeekEntry {
        WeekEntry(date: .now, count: 2)
    }

    func getSnapshot(in context: Context, completion: @escaping (WeekEntry) -> Void) {
        completion(WeekEntry(date: .now, count: currentCount()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeekEntry>) -> Void) {
        let entry = WeekEntry(date: .now, count: currentCount())
        // セッション完了時はアプリ側が reloadAllTimelines() で即時更新する。
        // ここでは週またぎで表示が古くならないよう翌日0時に再評価するだけ
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
        let midnight = Calendar.current.startOfDay(for: tomorrow)
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }

    /// アプリ本体の WeeklyCounter と同じ App Group / キー形式を読む
    private func currentCount() -> Int {
        let defaults = UserDefaults(suiteName: "group.com.shigihara.shinkokyu")
        guard let dict = defaults?.dictionary(forKey: "weeklyCount") as? [String: Int] else { return 0 }
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = .current
        let week = cal.component(.weekOfYear, from: .now)
        let year = cal.component(.yearForWeekOfYear, from: .now)
        return dict["\(year)-W\(week)"] ?? 0
    }
}

// MARK: - 表示

/// ロゴ B-2「めぐる波紋」のウィジェット用ミニ版 (96×96デザイン座標)
struct WidgetRippleMark: View {
    var color: Color

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

    private func ripple(radius: CGFloat, lineWidth: CGFloat, u: CGFloat) -> some View {
        Circle()
            .trim(from: 0.14, to: 1.0)
            .rotation(.degrees(64.8))
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth * u, lineCap: .round))
            .frame(width: radius * 2 * u, height: radius * 2 * u)
            .position(x: 48 * u, y: 36 * u)
    }
}

struct ShinkokyuWidgetView: View {
    var entry: WeekEntry
    @Environment(\.colorScheme) private var colorScheme

    // アプリ本体の Palette と同じ値 (sRGB)
    private var matsu: Color { Color(red: 0.1866, green: 0.3909, blue: 0.3150) }
    private var sumi: Color { Color(red: 0.0733, green: 0.1379, blue: 0.1153) }
    private var kasumi: Color { Color(red: 0.8896, green: 0.9352, blue: 0.9099) }
    private var wakaba: Color { Color(red: 0.6715, green: 0.7728, blue: 0.7139) }

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        VStack(spacing: 9) {
            WidgetRippleMark(color: isDark ? kasumi : matsu)
                .frame(width: 44, height: 44)
            Text("森呼吸")
                .font(.system(size: 15, weight: .semibold, design: .serif))
                .tracking(3)
                .foregroundStyle(isDark ? kasumi : sumi)
            Text("今週 \(entry.count)回")
                .font(.system(size: 11))
                .tracking(1)
                .foregroundStyle(isDark ? wakaba : sumi.opacity(0.55))
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: isDark
                    ? [Color(red: 0.1080, green: 0.2386, blue: 0.1917),
                       Color(red: 0.0392, green: 0.1220, blue: 0.0978)]
                    : [Color(red: 0.9587, green: 0.9766, blue: 0.9658),
                       Color(red: 0.8767, green: 0.9313, blue: 0.9011)],
                startPoint: .top, endPoint: .bottom
            )
        }
    }
}

// MARK: - ウィジェット定義

struct ShinkokyuWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ShinkokyuWidget", provider: WeekProvider()) { entry in
            ShinkokyuWidgetView(entry: entry)
        }
        .configurationDisplayName("森呼吸")
        .description("今週の森呼吸の回数。タップしてひと息。")
        .supportedFamilies([.systemSmall])
    }
}

@main
struct ShinkokyuWidgetBundle: WidgetBundle {
    var body: some Widget {
        ShinkokyuWidget()
    }
}

#Preview(as: .systemSmall) {
    ShinkokyuWidget()
} timeline: {
    WeekEntry(date: .now, count: 2)
}
