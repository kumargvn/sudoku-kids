import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var progress: ProgressStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    SectionTitle(text: "Pictures or numbers?")
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                        ForEach(SymbolSet.allCases) { set in
                            let isOn = progress.prefs.symbols == set
                            Button {
                                Feedback.tap()
                                progress.updatePrefs { $0.symbols = set }
                            } label: {
                                VStack(spacing: 4) {
                                    Text(set.preview).font(.system(size: 24, weight: .heavy, design: .rounded))
                                    Text(set.title).font(Theme.font(14, .bold))
                                }
                                .foregroundStyle(isOn ? .white : Theme.ink)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(isOn ? Theme.entry : Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .buttonStyle(BouncyButtonStyle())
                            .accessibilityAddTraits(isOn ? .isSelected : [])
                        }
                    }
                    Text("Used in Play and Practice. Adventure worlds bring their own pictures.")
                        .font(Theme.font(13, .medium))
                        .foregroundStyle(Theme.softInk)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    SectionTitle(text: "Playing")
                    VStack(spacing: 0) {
                        SettingToggle(icon: "xmark.circle.fill", color: Theme.mistake, title: "Show mistakes right away",
                                      detail: "Wrong squares turn red. When off, they show at the end.",
                                      isOn: binding(\.showMistakes))
                        Divider().padding(.leading, 52)
                        SettingToggle(icon: "heart.fill", color: Theme.mistake, title: "3-mistake challenge",
                                      detail: "In Play, three mistakes and it's game over.",
                                      isOn: binding(\.threeStrikes))
                        Divider().padding(.leading, 52)
                        SettingToggle(icon: "speaker.wave.2.fill", color: Theme.entry, title: "Read hints out loud",
                                      detail: "Great for kids who are still learning to read.",
                                      isOn: binding(\.readHintsAloud))
                    }
                    .card()

                    SectionTitle(text: "This device")
                    VStack(spacing: 0) {
                        SettingToggle(icon: "music.note", color: Difficulty.expert.color, title: "Sounds",
                                      detail: nil, isOn: $progress.settings.sound)
                        Divider().padding(.leading, 52)
                        SettingToggle(icon: "iphone.radiowaves.left.and.right", color: Difficulty.hard.color, title: "Vibration",
                                      detail: nil, isOn: $progress.settings.haptics)
                    }
                    .card()
                }
                .padding(20)
            }
            .kidsBackground()
            .navigationTitle("Settings for \(progress.profile.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.font(Theme.font(17, .bold))
                }
            }
        }
    }

    private func binding(_ key: WritableKeyPath<PlayerPrefs, Bool>) -> Binding<Bool> {
        Binding(
            get: { progress.prefs[keyPath: key] },
            set: { value in progress.updatePrefs { $0[keyPath: key] = value } }
        )
    }
}

struct SettingToggle: View {
    let icon: String
    let color: Color
    let title: String
    let detail: String?
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(color, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(Theme.font(16, .bold)).foregroundStyle(Theme.ink)
                    if let detail {
                        Text(detail).font(Theme.font(13, .medium)).foregroundStyle(Theme.softInk)
                    }
                }
            }
        }
        .tint(Difficulty.easy.color)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}
