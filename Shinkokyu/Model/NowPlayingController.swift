import MediaPlayer
import UIKit

/// ロック画面・コントロールセンターの再生表示と操作。
/// 表示: 「場所名 — 森呼吸」+ 景の写真 / 操作: 再生・一時停止のみ(曲送り等は無効)。
final class NowPlayingController {

    var onTogglePause: (() -> Void)?

    init() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { [weak self] _ in self?.toggle(); return .success }
        center.pauseCommand.addTarget { [weak self] _ in self?.toggle(); return .success }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in self?.toggle(); return .success }
        for command in [center.nextTrackCommand, center.previousTrackCommand,
                        center.skipForwardCommand, center.skipBackwardCommand,
                        center.changePlaybackPositionCommand] {
            command.isEnabled = false
        }
    }

    private func toggle() {
        DispatchQueue.main.async { [weak self] in self?.onTogglePause?() }
    }

    /// セッション開始: 場所名と景の写真をロック画面へ
    func begin(scene: ForestScene, duration: TimeInterval) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: scene.place,
            MPMediaItemPropertyArtist: "森呼吸",
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: 0.0,
            MPNowPlayingInfoPropertyPlaybackRate: 1.0,
        ]
        if let url = Bundle.main.url(forResource: scene.photoName, withExtension: "heic"),
           let image = UIImage(contentsOfFile: url.path) {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    /// 呼吸開始・一時停止・再開で進行状態を合わせる(以降はOSがrateから補間する)
    func update(elapsed: TimeInterval, isPaused: Bool) {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsed
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPaused ? 0.0 : 1.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    func clear() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
}
