import SwiftUI

/// S01: title, the next level, the Daily Challenge and settings.
struct HomeScreen: View {
    let onPlay: () -> Void
    let onDaily: () -> Void

    @Environment(PlayerProgress.self) private var progress
    @State private var showSettings = false
    @State private var breathe = false

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Label("\(progress.totalStars)", systemImage: "star.fill")
                    .font(Theme.body(18))
                    .foregroundStyle(Theme.leafDeep)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(.ultraThinMaterial))
                    .accessibilityLabel("\(progress.totalStars) stars")
                Spacer()
                RoundIconButton(systemName: "gearshape.fill", label: "Settings") { showSettings = true }
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 0)

            FloatingTiles()
                .frame(height: 120)

            VStack(spacing: -6) {
                Text("Meadow")
                    .font(Theme.display(58))
                Text("Mahjong")
                    .font(Theme.display(44))
            }
            .foregroundStyle(LinearGradient(colors: [.white, Color(hex: 0xE6FFD9)], startPoint: .top, endPoint: .bottom))
            .shadow(color: Theme.leafDeep, radius: 0, x: 2, y: 3)
            .shadow(color: Theme.leafDeep.opacity(0.5), radius: 10, y: 6)
            .accessibilityElement(children: .combine)

            Spacer(minLength: 0)

            Button(action: onPlay) {
                VStack(spacing: 2) {
                    Text("Play")
                        .font(Theme.display(34))
                    Text("Level \(progress.level)")
                        .font(Theme.body(18))
                        .opacity(0.9)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .scaleEffect(breathe ? 1.03 : 1)
            .shadow(color: Theme.sunshine.opacity(breathe ? 0.6 : 0.1), radius: 18)
            .padding(.horizontal, 40)

            Button(action: onDaily) {
                HStack(spacing: 14) {
                    Image(systemName: "calendar")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.blossom))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily Challenge")
                            .font(Theme.title(20))
                            .foregroundStyle(Theme.ink)
                        Text(progress.isSolved(.today) ? "Solved today. See you tomorrow!" : "A new puzzle every day")
                            .font(Theme.body(15))
                            .foregroundStyle(Theme.ink.opacity(0.65))
                    }
                    Spacer()
                    Image(systemName: progress.isSolved(.today) ? "trophy.fill" : "chevron.right")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(progress.isSolved(.today) ? Theme.sunshine : Theme.leaf)
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 24).fill(Theme.card.opacity(0.92)))
                .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(.white, lineWidth: 2))
            }
            .buttonStyle(PressableStyle())
            .padding(.horizontal, 28)

            Button {
                showSettings = true
            } label: {
                Label(progress.scenery.title, systemImage: progress.scenery.symbol)
                    .font(Theme.body(16))
                    .foregroundStyle(Theme.leafDeep)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(.ultraThinMaterial))
            }
            .accessibilityHint("Change the scene")
            .padding(.bottom, 12)
        }
        .frame(maxWidth: Theme.contentWidth)
        .padding(.top, 8)
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
                .presentationDetents([.large])
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { breathe = true }
        }
    }
}

/// Three tiles bobbing on the breeze above the title.
private struct FloatingTiles: View {
    private let faces = [TileFace(suit: .nature, rank: 1), TileFace(suit: .dragon, rank: 1), TileFace(suit: .season, rank: 3)]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            HStack(spacing: 14) {
                ForEach(faces.indices, id: \.self) { i in
                    TileView(face: faces[i], size: CGSize(width: 66, height: 86))
                        .rotationEffect(.degrees(sin(t * 1.1 + Double(i) * 1.4) * 8 + Double(i - 1) * 8))
                        .offset(y: sin(t * 1.4 + Double(i) * 2) * 8 + (i == 1 ? -14 : 0))
                }
            }
        }
        .accessibilityHidden(true)
    }
}
