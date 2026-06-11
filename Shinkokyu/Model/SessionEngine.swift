import Foundation
import Combine

/// 呼吸セッションの状態機械。
/// 3分(180秒) = 12秒ループ(吸う4秒/吐く8秒) × 15サイクル。
/// 終了は「180秒経過後、現在の吐く動作が終わった時点」— 吐き切りで終わる。
@MainActor
final class SessionEngine: ObservableObject {

    enum BreathPhase { case inhale, exhale }

    /// デモ用 (-demo30): デザインプロトタイプと同じ30秒=3サイクル短縮版
    static let sessionLength: TimeInterval =
        ProcessInfo.processInfo.arguments.contains("-demo30") ? 30 : 180
    static let inhaleDuration: TimeInterval = 4
    static let exhaleDuration: TimeInterval = 8   // 吸:吐 = 1:2 のリラックス比

    @Published private(set) var phase: BreathPhase = .inhale
    @Published private(set) var remaining: Int = Int(sessionLength)
    /// 現在のフェーズの残り秒(カウントダウン表示用)。4,3,2,1 / 8,7,...,1
    @Published private(set) var phaseRemaining: Int = Int(inhaleDuration)
    @Published private(set) var isPaused = false

    var onPhaseChange: ((BreathPhase) -> Void)?
    var onPauseChange: ((Bool) -> Void)?
    var onFinish: (() -> Void)?

    /// 完了済みフェーズの累計時間。一時停止で中断したフェーズは数えない
    /// (再開は「吸う」の頭からやり直すため)。
    private var completedTime: TimeInterval = 0
    private var phaseStart: Date = .now
    private var timer: Timer?

    func start() {
        completedTime = 0
        isPaused = false
        remaining = Int(Self.sessionLength)
        beginPhase(.inhale)
        let t = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        t.tolerance = 0.02
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func togglePause() {
        isPaused ? resume() : pause()
    }

    private func pause() {
        guard !isPaused else { return }
        isPaused = true
        onPauseChange?(true)
    }

    private func resume() {
        guard isPaused else { return }
        isPaused = false
        beginPhase(.inhale)
        onPauseChange?(false)
    }

    private func beginPhase(_ p: BreathPhase) {
        phase = p
        phaseStart = .now
        phaseRemaining = Int(p == .inhale ? Self.inhaleDuration : Self.exhaleDuration)
        onPhaseChange?(p)
    }

    private var phaseDuration: TimeInterval {
        phase == .inhale ? Self.inhaleDuration : Self.exhaleDuration
    }

    private func tick() {
        guard !isPaused, timer != nil else { return }
        let inPhase = Date.now.timeIntervalSince(phaseStart)
        let elapsed = completedTime + min(inPhase, phaseDuration)
        remaining = max(0, Int((Self.sessionLength - elapsed).rounded(.up)))
        phaseRemaining = max(1, Int((phaseDuration - inPhase).rounded(.up)))

        guard inPhase >= phaseDuration else { return }
        completedTime += phaseDuration

        if phase == .exhale && completedTime >= Self.sessionLength {
            stop()
            onFinish?()
            return
        }
        beginPhase(phase == .inhale ? .exhale : .inhale)
    }
}
