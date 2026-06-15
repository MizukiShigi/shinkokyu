import Foundation
import Combine

/// 呼吸セッションの状態機械。
/// 3分(180秒) = 12秒ループ(吸う4秒/吐く8秒) × 15サイクル。
/// 終了は「180秒経過後、現在の吐く動作が終わった時点」— 吐き切りで終わる。
///
/// 経過時間は壁時計の絶対時刻だけから算出する(一時停止ぶんは除外)。
/// タイマー発火の間引き(画面ロック/バックグラウンド)で誤差が累積しないようにするため。
@MainActor
final class SessionEngine: ObservableObject {

    enum BreathPhase { case inhale, exhale }

    /// デモ用 (-demo30): デザインプロトタイプと同じ30秒=3サイクル短縮版
    static let sessionLength: TimeInterval =
        ProcessInfo.processInfo.arguments.contains("-demo30") ? 30 : 180
    static let inhaleDuration: TimeInterval = 4
    static let exhaleDuration: TimeInterval = 8   // 吸:吐 = 1:2 のリラックス比
    private static var cycle: TimeInterval { inhaleDuration + exhaleDuration }  // 12

    /// 吐き切りで終わる: sessionLength以上で最初に来る「吐く」の終端。
    /// 180は12の倍数なのでちょうど180s。30(デモ)は36s。
    private static var effectiveEnd: TimeInterval {
        (sessionLength / cycle).rounded(.up) * cycle
    }

    @Published private(set) var phase: BreathPhase = .inhale
    @Published private(set) var remaining: Int = Int(sessionLength)
    /// 現在のフェーズの残り秒(カウントダウン表示用)。4,3,2,1 / 8,7,...,1
    @Published private(set) var phaseRemaining: Int = Int(inhaleDuration)
    /// 呼吸の進捗。0=収縮(吐き切り) / 1=拡張(吸い切り)。円の拡縮・明度はこれから描画する。
    /// 壁時計から毎tick算出するので、一時停止でtickが止まれば値も止まる=円もその場で凍結する。
    @Published private(set) var breath: Double = 0
    @Published private(set) var isPaused = false

    var onPauseChange: ((Bool) -> Void)?
    var onFinish: (() -> Void)?

    /// 一時停止を除いた実経過時間。現在の稼働区間の開始時刻 + それ以前の累計。
    private var accumulatedActive: TimeInterval = 0
    private var segmentStart: Date = .now
    private var timer: Timer?

    /// セッション開始からの実経過秒(一時停止中は進まない)
    private var elapsed: TimeInterval {
        accumulatedActive + (isPaused ? 0 : Date.now.timeIntervalSince(segmentStart))
    }

    func start() {
        accumulatedActive = 0
        segmentStart = .now
        isPaused = false
        phase = .inhale
        remaining = Int(Self.sessionLength)
        phaseRemaining = Int(Self.inhaleDuration)
        breath = 0
        let t = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        t.tolerance = 0.02
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        invalidate()
        isPaused = false
        accumulatedActive = 0
        phase = .inhale
        remaining = Int(Self.sessionLength)
        phaseRemaining = Int(Self.inhaleDuration)
        breath = 0
    }

    /// 0..1 を両端だけ柔らかい曲線へ(吸う/吐くの心地よい加減速)
    private func eased(_ t: Double) -> Double {
        let c = min(max(t, 0), 1)
        return c * c * (3 - 2 * c)
    }

    func togglePause() {
        isPaused ? resume() : pause()
    }

    private func pause() {
        guard !isPaused else { return }
        // 呼吸中(タイマー稼働中)のみ経過を確定する。イントロ中(timer == nil)は時間軸に触れない。
        if timer != nil {
            accumulatedActive += Date.now.timeIntervalSince(segmentStart)
        }
        isPaused = true
        onPauseChange?(true)
    }

    private func resume() {
        guard isPaused else { return }
        if timer != nil {
            // 止めていた地点からそのまま継続する(巻き戻さない=総時間は変わらない)。
            // フェーズ/残りは次の tick が elapsed から再計算する。
            segmentStart = .now
        }
        isPaused = false
        onPauseChange?(false)
    }

    private func invalidate() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard !isPaused, timer != nil else { return }
        let e = elapsed
        remaining = max(0, Int((Self.sessionLength - e).rounded(.up)))

        // 吐き切りの終端に到達 → 終了(鐘)
        if e >= Self.effectiveEnd {
            invalidate()
            remaining = 0
            phase = .exhale
            phaseRemaining = 1
            breath = 0
            onFinish?()
            return
        }

        // 現在位置からフェーズ・カウントダウン・呼吸進捗を導出(累積ドリフト無し)
        let p = e.truncatingRemainder(dividingBy: Self.cycle)
        if p < Self.inhaleDuration {
            phase = .inhale
            phaseRemaining = max(1, Int((Self.inhaleDuration - p).rounded(.up)))
            breath = eased(p / Self.inhaleDuration)               // 0 → 1
        } else {
            phase = .exhale
            phaseRemaining = max(1, Int((Self.cycle - p).rounded(.up)))
            breath = 1 - eased((p - Self.inhaleDuration) / Self.exhaleDuration)  // 1 → 0
        }
    }
}
