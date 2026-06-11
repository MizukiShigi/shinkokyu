import SwiftUI

/// セッション(本体): 写真が主役。UIは半透明の白とヘアラインだけで構成する。
/// 画面の文字は「場所名+現地情報 / 呼吸円 / 残り時間+一時停止」の3種のみ。
/// 写真は30秒ごとに同じ時間帯の景へ2秒クロスフェード(場所名も追従)。環境音は最初の景のまま。
struct SessionView: View {
    @ObservedObject var engine: SessionEngine
    let scene: ForestScene
    let onAbort: () -> Void
    /// 導入(メッセージ→3・2・1)が終わった瞬間に呼ばれる。ここでエンジンが動き出す
    let onIntroFinished: () -> Void

    /// 開始前の導入シーケンス
    private enum IntroStep: Equatable {
        case hidden
        case message
        case count(Int)
        case done
    }

    @State private var introStep: IntroStep = .hidden
    /// 導入の文字の明滅(内容の切替は不可視の間に行う)
    @State private var introOpacity: Double = 0
    @State private var currentScene: ForestScene
    @State private var currentPhoto: UIImage?
    @State private var sceneIndex = 0
    /// 呼吸円の拡縮はフェーズ変化に明示的に紐付ける(吸う4秒で1.0→1.4 / 吐く8秒で1.4→1.0)
    @State private var circleExpanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// 写真の切替間隔(デモ時は10秒に短縮)
    private static var photoIntervalSeconds: Int {
        SessionEngine.sessionLength >= 180 ? 30 : 10
    }

    init(engine: SessionEngine, scene: ForestScene,
         onAbort: @escaping () -> Void, onIntroFinished: @escaping () -> Void) {
        self.engine = engine
        self.scene = scene
        self.onAbort = onAbort
        self.onIntroFinished = onIntroFinished
        _currentScene = State(initialValue: scene)
    }

    private var isInhale: Bool { engine.phase == .inhale }
    private var timeLabel: String {
        String(format: "%d:%02d", engine.remaining / 60, engine.remaining % 60)
    }

    /// 拡縮レンジ。デザイン原案は1.40だが、吸う4秒の移動速度が吐く8秒の2倍になり
    /// 速く感じるため、吸うのピーク速度が「吐くの心地よい速度」と揃う1.28に調整。
    private static let expandedScale: CGFloat = 1.28

    /// 吸うはほぼ等速のなめらかなカーブ(両端だけ柔らかく)でピーク速度を最小に。
    /// 吐くは好評のease-in-outのまま。
    private var inhaleAnimation: Animation {
        .timingCurve(0.45, 0.05, 0.55, 0.95, duration: SessionEngine.inhaleDuration)
    }
    private var exhaleAnimation: Animation {
        .easeInOut(duration: SessionEngine.exhaleDuration)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // ---- 写真 (full-bleed + 写真ごとのKen Burns + 30秒クロスフェード) ----
                if let currentPhoto {
                    KenBurnsPhoto(
                        image: currentPhoto,
                        width: geo.size.width,
                        height: geo.size.height,
                        animated: !reduceMotion
                    )
                    .id(currentScene.id)
                    .transition(.opacity)
                } else {
                    Palette.shinrin
                }

                // ---- スクリム (上36%・墨38% / 下32%・墨42%) ----
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [Palette.scrim.opacity(0.38), .clear],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: geo.size.height * 0.36)
                    Spacer(minLength: 0)
                    LinearGradient(
                        colors: [.clear, Palette.scrim.opacity(0.42)],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: geo.size.height * 0.32)
                }

                // ---- コンテンツ (デザイン値: 上86 / 下64) ----
                VStack(spacing: 0) {
                    VStack(spacing: 9) {
                        Text(currentScene.place)
                            .font(AppFont.gothic(15))
                            .tracking(3)
                            .padding(.leading, 3)
                            .foregroundStyle(.white.opacity(0.95))
                        Text(currentScene.info)
                            .font(AppFont.gothic(11.5))
                            .tracking(2.5)
                            .padding(.leading, 2.5)
                            .foregroundStyle(.white.opacity(0.65))
                    }
                    .id("label-" + currentScene.id)
                    .transition(.opacity)
                    .padding(.top, 86)

                    Spacer()

                    breathingCircle

                    Spacer()

                    VStack(spacing: 16) {
                        Text(timeLabel)
                            .font(AppFont.gothic(16))
                            .tracking(1.9)
                            .monospacedDigit()
                            .foregroundStyle(.white.opacity(0.92))

                        // 一時停止は呼吸が始まってから
                        if introStep == .done {
                            Button(action: { engine.togglePause() }) {
                                ZStack {
                                    Circle()
                                        .stroke(.white.opacity(engine.isPaused ? 0.9 : 0.45), lineWidth: 1)
                                        .frame(width: 46, height: 46)
                                    if engine.isPaused {
                                        PlayTriangle()
                                            .fill(.white.opacity(0.9))
                                            .frame(width: 13, height: 16)
                                            .offset(x: 2)
                                    } else {
                                        HStack(spacing: 5) {
                                            Capsule().frame(width: 3, height: 14)
                                            Capsule().frame(width: 3, height: 14)
                                        }
                                        .foregroundStyle(.white.opacity(0.9))
                                    }
                                }
                            }
                            .transition(.opacity)
                        }

                        // 一時停止中にだけ現れる、唯一の中断手段
                        if engine.isPaused {
                            Button(action: onAbort) {
                                Text("おわる")
                                    .font(AppFont.gothic(12.5))
                                    .tracking(3.1)
                                    .padding(.leading, 3.1)
                                    .foregroundStyle(.white.opacity(0.7))
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 18)
                            }
                            .transition(.opacity)
                        }
                    }
                    .animation(.easeInOut(duration: 0.5), value: engine.isPaused)
                    .padding(.bottom, 64)
                }
            }
        }
        .ignoresSafeArea() // 写真を物理画面いっぱいに
        .onAppear {
            currentPhoto = loadPhoto(scene)
            scheduleIntro()
        }
        .onChange(of: engine.remaining) { _, remaining in
            advancePhotoIfNeeded(remaining: remaining)
        }
        .onChange(of: engine.phase) { _, newPhase in
            guard !engine.isPaused else { return }
            switch newPhase {
            case .inhale:
                withAnimation(inhaleAnimation) { circleExpanded = true }
            case .exhale:
                withAnimation(exhaleAnimation) { circleExpanded = false }
            }
        }
        .onChange(of: engine.isPaused) { _, paused in
            if paused {
                // 停止中は静かに基準サイズへ戻す
                withAnimation(.easeInOut(duration: 1.0)) { circleExpanded = false }
            } else {
                // 再開は常に「吸う」の頭から
                withAnimation(inhaleAnimation) { circleExpanded = true }
            }
        }
    }

    /// 導入: 景色と環境音が立ち上がる → メッセージがゆっくり現れて消える
    /// → 3・2・1(それぞれ柔らかく明滅) → ひと呼吸おいて最初の「吸う」
    private func scheduleIntro() {
        func at(_ t: TimeInterval, _ action: @escaping () -> Void) {
            DispatchQueue.main.asyncAfter(deadline: .now() + t, execute: action)
        }
        // メッセージ: 画面のクロスフェードが落ち着いてから、読む時間をとって静かに消える
        at(0.8) {
            introStep = .message
            withAnimation(.easeInOut(duration: 1.2)) { introOpacity = 1 }
        }
        at(4.6) {
            withAnimation(.easeInOut(duration: 0.6)) { introOpacity = 0 }
        }
        // 3・2・1: 1.8秒間隔(数字の間に0.5秒の静かな間)。
        // 3と2は短く明滅、1だけゆっくり溶けて呼吸へつながる
        for (i, n) in [3, 2, 1].enumerated() {
            let base = 5.4 + Double(i) * 1.8
            at(base) {
                introStep = .count(n)
                withAnimation(.easeInOut(duration: 0.4)) { introOpacity = 1 }
            }
            at(base + 0.9) {
                withAnimation(.easeInOut(duration: n == 1 ? 1.5 : 0.4)) { introOpacity = 0 }
            }
        }
        // 「1」(9.0表示) が溶けきった瞬間に最初の「吸う」が始まる
        at(11.5) {
            introStep = .done
            onIntroFinished()
            withAnimation(.easeInOut(duration: 0.5)) { introOpacity = 1 }
            withAnimation(inhaleAnimation) { circleExpanded = true }
        }
    }

    /// 経過時間から写真インデックスを求め、進んでいたら次の景へクロスフェード。
    /// 一時停止中は remaining が止まる = ローテーションも止まる。
    private func advancePhotoIfNeeded(remaining: Int) {
        let elapsed = Int(SessionEngine.sessionLength) - remaining
        let idx = elapsed / Self.photoIntervalSeconds
        guard idx > sceneIndex else { return }
        sceneIndex = idx

        let rotation = SceneCatalog.rotation(startingAt: scene)
        let next = rotation[idx % rotation.count]
        guard next.id != currentScene.id, let img = loadPhoto(next) else { return }
        withAnimation(.easeInOut(duration: 2.0)) {
            currentScene = next
            currentPhoto = img
        }
    }

    private func loadPhoto(_ s: ForestScene) -> UIImage? {
        guard let url = Bundle.main.url(forResource: s.photoName, withExtension: "heic") else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    /// 呼吸円: scale 1.00⇄1.28 / 輪郭 55⇄85% / 充填 10⇄18%
    private var breathingCircle: some View {
        let scale: CGFloat = reduceMotion ? 1.14 : (circleExpanded ? Self.expandedScale : 1.0)

        return ZStack {
            Circle()
                .stroke(.white.opacity(0.12), lineWidth: 1)
                .frame(width: 276, height: 276)
            Circle()
                .stroke(.white.opacity(0.20), lineWidth: 1)
                .frame(width: 232, height: 232)

            // 動くのは円だけ。文字は拡縮の外に置いて固定する
            ZStack {
                Circle()
                    .fill(.white.opacity(circleExpanded ? 0.18 : 0.10))
                    .background(.ultraThinMaterial.opacity(0.5), in: Circle())
                Circle()
                    .stroke(.white.opacity(circleExpanded ? 0.85 : 0.55), lineWidth: 1.5)
            }
            .frame(width: 176, height: 176)
            .scaleEffect(scale)

            // 円の中身: 導入メッセージ → 3・2・1 → 吸う/吐く
            Group {
                switch introStep {
                case .hidden:
                    EmptyView()
                case .message:
                    Text("森の中にいることを\n想像して、ゆっくり\n深呼吸しましょう")
                        .font(AppFont.mincho(13.5))
                        .tracking(2)
                        .lineSpacing(9)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.95))
                case .count(let n):
                    Text("\(n)")
                        .font(AppFont.mincho(40))
                        .foregroundStyle(.white.opacity(0.95))
                case .done:
                    VStack(spacing: 8) {
                        Text(isInhale ? "吸う" : "吐く")
                            .font(AppFont.gothic(19))
                            .tracking(6.5)
                            .padding(.leading, 6.5)
                            .foregroundStyle(.white.opacity(0.95))
                        Text("\(engine.phaseRemaining)秒")
                            .font(AppFont.gothic(11))
                            .tracking(2)
                            .padding(.leading, 2)
                            .monospacedDigit()
                            .foregroundStyle(.white.opacity(0.66))
                    }
                }
            }
            // 内容の切替は即時(不可視の間に行う)。明滅は外側の opacity が担う
            .transaction { $0.animation = nil }
            .opacity(introOpacity)
        }
        .frame(width: 280, height: 280)
    }
}

/// 写真1枚ぶんのKen Burns: 表示されている間 1.00→1.05 / linear。
/// .id() で差し替わるたびに新しいインスタンスになり、ズームが掛け直される。
struct KenBurnsPhoto: View {
    let image: UIImage
    let width: CGFloat
    let height: CGFloat
    let animated: Bool

    @State private var zoom = false

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: width, height: height)
            .scaleEffect(zoom ? 1.05 : 1.0)
            .clipped()
            .onAppear {
                guard animated else { return }
                // 切替間隔(30秒)より少し長めに動かし続ける
                withAnimation(.linear(duration: 34)) { zoom = true }
            }
    }
}

struct PlayTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
