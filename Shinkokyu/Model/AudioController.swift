import AVFoundation

/// 環境音(3分半のフィールドレコーディング)と終了の鐘。
/// フェードはすべてランタイム: 開始2.0sフェードイン / 終了は鐘 + 6.0sフェードアウト。
final class AudioController: NSObject {

    private var ambient: AVAudioPlayer?
    private var bell: AVAudioPlayer?

    /// 着信などのオーディオ中断 → セッションを自動ポーズさせる
    var onInterruption: (() -> Void)?

    override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    func startSession(soundName: String) {
        let session = AVAudioSession.sharedInstance()
        // .playback: サイレントスイッチONでも環境音を鳴らす
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)

        guard let url = Bundle.main.url(forResource: soundName, withExtension: "m4a") else { return }
        ambient = try? AVAudioPlayer(contentsOf: url)
        // 素材は210秒ちょうど。一時停止でセッションが延びた場合の保険に1回ループ
        ambient?.numberOfLoops = 1
        ambient?.volume = 0
        ambient?.prepareToPlay()
        ambient?.play()
        ambient?.setVolume(1.0, fadeDuration: 2.0)
    }

    func pause() { ambient?.pause() }
    func resume() { ambient?.play() }

    /// 吐き切りの瞬間: 鐘を鳴らし、その余韻の下で環境音を6秒かけて絞る
    func finishSession() {
        if let url = Bundle.main.url(forResource: "bell-end", withExtension: "m4a") {
            bell = try? AVAudioPlayer(contentsOf: url)
            // 音量バランスは素材側で調整済み: 環境音 RMS -40dBFS / 鐘 -32dBFS
            bell?.volume = 1.0
            bell?.play()
        }
        ambient?.setVolume(0, fadeDuration: 6.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.5) { [weak self] in
            self?.ambient?.stop()
            self?.ambient = nil
        }
    }

    /// 途中でやめた場合: 鐘なしで速やかに絞る
    func abort() {
        ambient?.setVolume(0, fadeDuration: 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { [weak self] in
            self?.ambient?.stop()
            self?.ambient = nil
        }
    }

    @objc private func handleInterruption(_ note: Notification) {
        guard let info = note.userInfo,
              let raw = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: raw),
              type == .began else { return }
        DispatchQueue.main.async { [weak self] in self?.onInterruption?() }
    }
}
