import SwiftUI

/// S07 and S08: sound, haptics, tile dimming, and the scene picker.
struct SettingsSheet: View {
    @Environment(PlayerProgress.self) private var progress
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var progress = progress
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(spacing: 0) {
                        Toggle(isOn: $progress.soundOn) { Label("Sound", systemImage: "speaker.wave.2.fill") }
                            .padding(16)
                        Divider().padding(.leading, 16)
                        Toggle(isOn: $progress.hapticsOn) { Label("Vibration", systemImage: "iphone.radiowaves.left.and.right") }
                            .padding(16)
                        Divider().padding(.leading, 16)
                        Toggle(isOn: $progress.dimBlocked) {
                            VStack(alignment: .leading, spacing: 2) {
                                Label("Dim blocked tiles", systemImage: "circle.lefthalf.filled")
                                Text("Makes the free tiles easy to spot.")
                                    .font(Theme.body(14))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(16)
                    }
                    .font(Theme.body(18))
                    .tint(Theme.leaf)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemGroupedBackground)))

                    Text("Scenes")
                        .font(Theme.title(22))
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 14)], spacing: 14) {
                        ForEach(Scenery.allCases) { scene in
                            SceneCard(scene: scene,
                                      isSelected: progress.scenery == scene,
                                      isUnlocked: scene.isUnlocked(atLevel: progress.level)) {
                                progress.scenery = scene
                            }
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: Theme.contentWidth)
                .frame(maxWidth: .infinity)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.font(Theme.body(17))
                }
            }
        }
    }
}

private struct SceneCard: View {
    let scene: Scenery
    let isSelected: Bool
    let isUnlocked: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            ZStack(alignment: .bottomLeading) {
                NatureBackground(scenery: scene, animated: isSelected)
                    .frame(height: 130)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                LinearGradient(colors: [.clear, .black.opacity(0.45)], startPoint: .center, endPoint: .bottom)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                Text(scene.title)
                    .font(Theme.body(16))
                    .foregroundStyle(.white)
                    .padding(10)
                if !isUnlocked {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.black.opacity(0.45))
                        VStack(spacing: 4) {
                            Image(systemName: "lock.fill").font(.system(size: 24, weight: .bold))
                            Text("Level \(scene.unlockLevel)").font(Theme.body(15))
                        }
                        .foregroundStyle(.white)
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(isSelected ? Theme.sunshine : .clear, lineWidth: 4)
            )
        }
        .buttonStyle(PressableStyle())
        .disabled(!isUnlocked)
        .accessibilityLabel(scene.title)
        .accessibilityValue(isUnlocked ? (isSelected ? "Selected" : "") : "Unlocks at level \(scene.unlockLevel)")
    }
}
