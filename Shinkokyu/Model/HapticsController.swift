import CoreHaptics

/// 仕様: 吸う = 強度0→0.6へ4秒で立ち上がり / 吐く = 0.6→0へ8秒で減衰。
/// 目を閉じても呼吸を追える、視覚に依存しない設計。
final class HapticsController {

    private var engine: CHHapticEngine?
    private var player: CHHapticPatternPlayer?

    init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        engine = try? CHHapticEngine()
        engine?.resetHandler = { [weak self] in try? self?.engine?.start() }
        engine?.stoppedHandler = { _ in }
        try? engine?.start()
    }

    func playInhale() { play(duration: 4, from: 0.0, to: 0.6) }
    func playExhale() { play(duration: 8, from: 0.6, to: 0.0) }

    func stop() {
        try? player?.stop(atTime: CHHapticTimeImmediate)
        player = nil
    }

    private func play(duration: TimeInterval, from: Float, to: Float) {
        guard let engine else { return }
        // バックグラウンドから復帰した直後はエンジンが止まっているため毎回起こす
        // (起動済みなら何もしないのでコストは無視できる)
        try? engine.start()
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3),
            ],
            relativeTime: 0,
            duration: duration
        )
        let curve = CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [
                .init(relativeTime: 0, value: from),
                .init(relativeTime: duration, value: to),
            ],
            relativeTime: 0
        )
        guard let pattern = try? CHHapticPattern(events: [event], parameterCurves: [curve]) else { return }
        try? player?.stop(atTime: CHHapticTimeImmediate)
        player = try? engine.makePlayer(with: pattern)
        try? player?.start(atTime: CHHapticTimeImmediate)
    }
}
