import SwiftUI

/// S02: the board, with its top bar, combo meter, help tools and overlays.
struct GameScreen: View {
    let model: GameModel
    let onHome: () -> Void
    let onNext: () -> Void

    @Environment(PlayerProgress.self) private var progress
    @State private var paused = false
    @State private var unlocked: Scenery?
    @State private var recorded = false

    var body: some View {
        ZStack {
            VStack(spacing: 6) {
                topBar
                ComboMeter(combo: model.combo, lastMatchAt: model.lastMatchAt)
                    .padding(.horizontal, 40)
                    .frame(maxWidth: 480)
                BoardView(model: model, dimBlocked: progress.dimBlocked)
                    .padding(.horizontal, 10)
                toolBar
            }
            .padding(.bottom, 8)

            if let praise = model.praise {
                PraiseView(praise: praise)
                    .id(praise.id)
                    .offset(y: -120)
                    .transition(.asymmetric(insertion: .identity, removal: .scale(scale: 1.3).combined(with: .opacity)))
            }

            if model.phase == .stuck {
                StuckCard(shuffleFailed: model.shuffleFailed,
                          canUndo: model.canUndo,
                          shuffle: model.shuffle,
                          undo: model.undo,
                          restart: model.restart)
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
            }

            if paused {
                PauseCard(resume: { paused = false },
                          restart: { paused = false; model.restart() },
                          home: onHome)
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
            }

            if model.phase == .won {
                WinOverlay(model: model, unlocked: unlocked, onNext: onNext, onHome: onHome)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.25), value: model.praise)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: model.phase)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: paused)
        .onChange(of: model.phase) { _, phase in
            guard phase == .won, !recorded else { return }
            recorded = true
            unlocked = progress.recordWin(model.config, stars: model.stars)
        }
    }

    // MARK: - Bars

    private var topBar: some View {
        HStack(spacing: 12) {
            RoundIconButton(systemName: "pause.fill", label: "Pause") { paused = true }
            Spacer()
            VStack(spacing: 0) {
                Text(model.config.isDaily ? "Daily Challenge" : model.config.title)
                    .font(Theme.title(22))
                    .foregroundStyle(Theme.leafDeep)
                if model.config.isDaily {
                    Text(model.config.title)
                        .font(Theme.body(14))
                        .foregroundStyle(Theme.leafDeep.opacity(0.7))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Capsule().fill(.ultraThinMaterial))     // readable on every scene, night included
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Label("\(model.tilesLeft)", systemImage: "square.stack.3d.up.fill")
                    .font(Theme.body(16))
                    .contentTransition(.numericText())
                Label("\(model.score)", systemImage: "star.fill")
                    .font(Theme.body(16))
                    .contentTransition(.numericText())
            }
            .monospacedDigit()
            .foregroundStyle(Theme.leafDeep)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
            .animation(.snappy, value: model.score)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(model.tilesLeft) tiles left, score \(model.score)")
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .frame(maxWidth: Theme.contentWidth)
    }

    private var toolBar: some View {
        HStack(spacing: 18) {
            ToolButton(systemName: "lightbulb.fill", title: "Hint", tint: Theme.sunshine, enabled: model.phase == .playing, action: model.useHint)
            ToolButton(systemName: "shuffle", title: "Shuffle", tint: Color(hex: 0x7FC8F8), enabled: model.phase != .won, action: model.shuffle)
            ToolButton(systemName: "arrow.uturn.backward", title: "Undo", tint: Theme.blossom, enabled: model.canUndo, action: model.undo)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: Theme.contentWidth)
    }
}

/// A big round help button with its name under it.
struct ToolButton: View {
    let systemName: String
    let title: String
    let tint: Color
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemName)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(
                        Circle()
                            .fill(LinearGradient(colors: [tint.opacity(0.85), tint], startPoint: .top, endPoint: .bottom))
                            .shadow(color: tint.opacity(0.6), radius: 6, y: 4)
                    )
                    .overlay(Circle().strokeBorder(.white.opacity(0.7), lineWidth: 2.5))
                Text(title)
                    .font(Theme.body(15))
                    .foregroundStyle(Theme.leafDeep)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(.white.opacity(0.75)))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PressableStyle())
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.45)
    }
}

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.5), value: configuration.isPressed)
    }
}

// MARK: - Overlays

/// S05: no pair is free.
private struct StuckCard: View {
    let shuffleFailed: Bool
    let canUndo: Bool
    let shuffle: () -> Void
    let undo: () -> Void
    let restart: () -> Void

    var body: some View {
        ZStack {
            Theme.scrim.ignoresSafeArea()
            VStack(spacing: 14) {
                Image(systemName: shuffleFailed ? "leaf.arrow.triangle.circlepath" : "shuffle.circle.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(Theme.leaf)
                Text("No more moves")
                    .font(Theme.title(28))
                    .foregroundStyle(Theme.ink)
                Text(shuffleFailed
                     ? "These tiles can't be cleared from here. Undo a few moves or start again."
                     : "Shuffle the tiles to keep going. It's free.")
                    .font(Theme.body(18))
                    .foregroundStyle(Theme.ink.opacity(0.75))
                    .multilineTextAlignment(.center)
                if !shuffleFailed {
                    Button("Shuffle", action: shuffle).buttonStyle(PrimaryButtonStyle())
                }
                if canUndo {
                    Button("Undo", action: undo).buttonStyle(SecondaryButtonStyle())
                }
                Button("Restart", action: restart).buttonStyle(SecondaryButtonStyle())
            }
            .card()
            .padding(28)
        }
    }
}

/// S06
private struct PauseCard: View {
    let resume: () -> Void
    let restart: () -> Void
    let home: () -> Void

    var body: some View {
        ZStack {
            Theme.scrim.ignoresSafeArea().onTapGesture(perform: resume)
            VStack(spacing: 14) {
                Text("Paused")
                    .font(Theme.title(30))
                    .foregroundStyle(Theme.ink)
                Text("Take a breath. The meadow will wait.")
                    .font(Theme.body(17))
                    .foregroundStyle(Theme.ink.opacity(0.7))
                Button("Resume", action: resume).buttonStyle(PrimaryButtonStyle())
                Button("Restart", action: restart).buttonStyle(SecondaryButtonStyle())
                Button("Home", action: home).buttonStyle(SecondaryButtonStyle())
            }
            .card()
            .padding(28)
        }
    }
}

/// S04: celebration, stars and the way on.
private struct WinOverlay: View {
    let model: GameModel
    let unlocked: Scenery?
    let onNext: () -> Void
    let onHome: () -> Void

    @Environment(Feedback.self) private var feedback
    @State private var appeared = false
    @State private var starsShown = 0
    @State private var headline = WinOverlay.headlines.randomElement() ?? "Brilliant!"

    private static let headlines = ["Brilliant!", "Wonderful!", "Superb!", "Well done!", "Marvellous!", "Splendid!"]

    var body: some View {
        ZStack {
            Theme.scrim.ignoresSafeArea()
            ConfettiView(count: 80, duration: 3.5)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text(headline)
                    .font(Theme.display(46))
                    .foregroundStyle(LinearGradient(colors: [Color(hex: 0xFFF1A1), Color(hex: 0xF29A1D)], startPoint: .top, endPoint: .bottom))
                    .shadow(color: Color(hex: 0x7A3E00), radius: 0, x: 2, y: 2)
                    .shadow(color: Color(hex: 0x7A3E00), radius: 0, x: -2, y: 2)
                    .shadow(color: Color(hex: 0x7A3E00), radius: 0, x: 2, y: -2)
                    .shadow(color: Color(hex: 0x7A3E00), radius: 0, x: -2, y: -2)
                    .scaleEffect(appeared ? 1 : 0.3)

                Text(model.config.isDaily ? "Daily Challenge solved" : "\(model.config.title) complete")
                    .font(Theme.title(20))
                    .foregroundStyle(Theme.ink)

                HStack(spacing: 10) {
                    ForEach(0..<3, id: \.self) { i in
                        let earned = i < model.stars
                        Image(systemName: model.config.isDaily && i == 1 ? "trophy.fill" : "star.fill")
                            .font(.system(size: i == 1 ? 58 : 44))
                            .foregroundStyle(earned
                                             ? AnyShapeStyle(LinearGradient(colors: [Color(hex: 0xFFF1A1), Color(hex: 0xF5A623)], startPoint: .top, endPoint: .bottom))
                                             : AnyShapeStyle(Color.gray.opacity(0.3)))
                            .shadow(color: earned ? Theme.sunshine.opacity(0.7) : .clear, radius: 8)
                            .scaleEffect(starsShown > i ? 1 : 0.01)
                            .rotationEffect(.degrees(starsShown > i ? 0 : -90))
                            .offset(y: i == 1 ? -8 : 0)
                    }
                }
                .frame(height: 72)

                VStack(spacing: 6) {
                    stat("Score", "\(model.score)")
                    stat("Best combo", "×\(model.bestCombo)")
                    stat("Time", Duration.seconds(model.elapsed).formatted(.time(pattern: .minuteSecond)))
                }
                .padding(.vertical, 6)

                if let unlocked {
                    Label("New scene: \(unlocked.title)", systemImage: unlocked.symbol)
                        .font(Theme.body(17))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Theme.leaf))
                }

                Button(model.config.isDaily ? "Done" : "Next Level", action: model.config.isDaily ? onHome : onNext)
                    .buttonStyle(PrimaryButtonStyle())
                if !model.config.isDaily {
                    Button("Home", action: onHome).buttonStyle(SecondaryButtonStyle())
                }
            }
            .card()
            .padding(24)
            .scaleEffect(appeared ? 1 : 0.8)
            .opacity(appeared ? 1 : 0)
        }
        .task {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { appeared = true }
            for i in 0..<model.stars {
                try? await Task.sleep(for: .seconds(i == 0 ? 0.45 : 0.3))
                withAnimation(.spring(response: 0.35, dampingFraction: 0.45)) { starsShown = i + 1 }
                feedback.star(i)
            }
        }
    }

    private func stat(_ name: String, _ value: String) -> some View {
        HStack {
            Text(name).foregroundStyle(Theme.ink.opacity(0.65))
            Spacer()
            Text(value).foregroundStyle(Theme.ink).monospacedDigit()
        }
        .font(Theme.body(18))
        .padding(.horizontal, 12)
    }
}
