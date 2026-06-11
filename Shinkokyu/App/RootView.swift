import SwiftUI

/// 画面遷移はすべてクロスフェード。スライドとバウンスは使わない。
struct RootView: View {

    enum Screen { case splash, home, session, okaeri }

    @State private var screen: Screen = .splash
    @State private var forestScene: ForestScene = SceneCatalog.current()
    @State private var weekCount = WeeklyCounter.thisWeek

    @StateObject private var engine = SessionEngine()
    @State private var audio = AudioController()
    @State private var haptics = HapticsController()
    @State private var nowPlaying = NowPlayingController()

    var body: some View {
        ZStack {
            if screen == .splash {
                SplashView()
                    .transition(.opacity)
            }
            if screen == .home {
                HomeView(weekCount: weekCount, isNight: isNightHome, onStart: startSession)
                    .transition(.opacity)
            }
            if screen == .session {
                SessionView(
                    engine: engine,
                    scene: forestScene,
                    onAbort: abortSession,
                    onIntroFinished: {
                        // 導入(3・2・1)が終わってから呼吸開始
                        engine.start()
                        nowPlaying.update(elapsed: 0, isPaused: false)
                    }
                )
                .transition(.opacity)
            }
            if screen == .okaeri {
                OkaeriView(onClose: { go(.home, duration: 0.8) })
                    .transition(.opacity)
            }
        }
        .statusBarHidden(screen == .splash)
        .preferredColorScheme(preferredScheme)
        .onAppear {
            // スプラッシュ1.2s滞在 → 0.8sフェード
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                go(.home, duration: 0.8)
                // UI検証用: 起動引数でセッションを自動開始
                if ProcessInfo.processInfo.arguments.contains("-autoStartSession") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { startSession() }
                }
            }
        }
        // バックグラウンド移行してもセッションは続く(UIBackgroundModes: audio)。
        // 環境音と鐘はロック中も鳴る。Hapticsと画面ガイドはiOSの仕様で停止する。
    }

    private var isNightHome: Bool {
        SceneCatalog.bucket() == .night
    }

    /// ステータスバーの色を画面の地色に合わせる
    private var preferredScheme: ColorScheme {
        switch screen {
        case .splash, .session: return .dark
        case .home: return isNightHome ? .dark : .light
        case .okaeri: return .light
        }
    }

    private func go(_ s: Screen, duration: Double) {
        withAnimation(.easeInOut(duration: duration)) {
            screen = s
        }
    }

    private func startSession() {
        forestScene = SceneCatalog.current()

        engine.onPhaseChange = { [weak haptics] phase in
            switch phase {
            case .inhale: haptics?.playInhale()
            case .exhale: haptics?.playExhale()
            }
        }
        engine.onPauseChange = { [weak audio, weak haptics, weak engine, weak nowPlaying] paused in
            if paused {
                audio?.pause()
                haptics?.stop()
            } else {
                audio?.resume()
                // 呼吸は engine が「吸う」の頭から再開 → onPhaseChange でHapticsも追従
            }
            let elapsed = SessionEngine.sessionLength - TimeInterval(engine?.remaining ?? 0)
            nowPlaying?.update(elapsed: max(0, elapsed), isPaused: paused)
        }
        engine.onFinish = { finishSession() }
        audio.onInterruption = {
            if screen == .session && !engine.isPaused { engine.togglePause() }
        }

        nowPlaying.onTogglePause = { [weak engine] in engine?.togglePause() }

        // 環境音はすぐ立ち上げ(2.0sフェードイン)、導入の間に音の空気を作る。
        // エンジンは導入が終わってから (onIntroFinished で start)
        audio.startSession(soundName: forestScene.soundName)
        nowPlaying.begin(scene: forestScene, duration: SessionEngine.sessionLength)
        UIApplication.shared.isIdleTimerDisabled = true
        go(.session, duration: 1.1)
    }

    /// 吐き切りの瞬間に呼ばれる: 鐘 → 環境音6sフェードアウト → おかえり
    private func finishSession() {
        audio.finishSession()
        haptics.stop()
        nowPlaying.clear()
        UIApplication.shared.isIdleTimerDisabled = false
        WeeklyCounter.increment()
        weekCount = WeeklyCounter.thisWeek
        go(.okaeri, duration: 1.1)
    }

    /// 一時停止中の「おわる」: 回数は数えず、静かにホームへ
    private func abortSession() {
        engine.stop()
        audio.abort()
        haptics.stop()
        nowPlaying.clear()
        UIApplication.shared.isIdleTimerDisabled = false
        go(.home, duration: 0.8)
    }
}

#Preview {
    RootView()
}
