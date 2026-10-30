import SwiftUI

@main
struct MeadowMahjongApp: App {
    @State private var progress: PlayerProgress
    @State private var feedback: Feedback

    init() {
        let progress = PlayerProgress()
        _progress = State(initialValue: progress)
        _feedback = State(initialValue: Feedback(progress: progress))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(progress)
                .environment(feedback)
        }
    }
}

/// Keeps one animated scene behind every screen, so the animation never restarts.
struct RootView: View {
    private enum Route: Equatable {
        case home, daily, game
    }

    @Environment(PlayerProgress.self) private var progress
    @Environment(Feedback.self) private var feedback
    @State private var route = Route.home
    @State private var game: GameModel?

    var body: some View {
        ZStack {
            NatureBackground(scenery: progress.scenery)
                .ignoresSafeArea()
                .id(progress.scenery)
                .transition(.opacity)

            switch route {
            case .home:
                HomeScreen(onPlay: { start(.level(progress.level)) },
                           onDaily: { route = .daily })
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            case .daily:
                DailyScreen(onPlay: { start(.daily($0)) },
                            onBack: { route = .home })
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .game:
                if let game {
                    GameScreen(model: game,
                               onHome: { route = .home },
                               onNext: { start(.level(progress.level)) })
                        .id(ObjectIdentifier(game))
                        .transition(.opacity.combined(with: .scale(scale: 1.04)))
                }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: route)
        .animation(.easeInOut(duration: 0.8), value: progress.scenery)
    }

    private func start(_ config: GameConfig) {
        game = GameModel(config: config, feedback: feedback)
        route = .game
    }
}
