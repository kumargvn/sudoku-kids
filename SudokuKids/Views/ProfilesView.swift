import SwiftUI

/// Lets siblings each keep their own stars, trophies and saved game.
struct ProfilesView: View {
    @EnvironmentObject private var progress: ProgressStore
    @Environment(\.dismiss) private var dismiss
    @State private var adding = false
    @State private var name = ""
    @State private var avatar = Profile.avatars[1]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    SectionTitle(text: "Who's playing?")
                    ForEach(progress.profiles) { profile in
                        Button {
                            progress.switchTo(profile.id)
                            Feedback.tap()
                            dismiss()
                        } label: {
                            HStack(spacing: 14) {
                                Text(profile.avatar)
                                    .font(.system(size: 34))
                                    .frame(width: 56, height: 56)
                                    .background(Theme.entry.opacity(0.12), in: Circle())
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(profile.name).font(Theme.font(19, .heavy)).foregroundStyle(Theme.ink)
                                    Text("⭐ \(profile.stats.totalStars)  ·  🏆 \(profile.stats.totalWins) solved")
                                        .font(Theme.font(14, .semibold))
                                        .foregroundStyle(Theme.softInk)
                                }
                                Spacer(minLength: 0)
                                if profile.id == progress.activeID {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 26))
                                        .foregroundStyle(Difficulty.easy.color)
                                }
                            }
                            .padding(14)
                            .card(radius: 20)
                        }
                        .buttonStyle(BouncyButtonStyle())
                    }

                    if adding {
                        newPlayerForm
                    } else if progress.canAddProfile {
                        Button {
                            adding = true
                            name = ""
                            avatar = Profile.avatars.first { a in !progress.profiles.contains { $0.avatar == a } } ?? Profile.avatars[1]
                        } label: {
                            Label("Add a player", systemImage: "plus.circle.fill")
                                .font(Theme.font(18, .heavy))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .foregroundStyle(Theme.entry)
                                .background(Theme.entry.opacity(0.12), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }
                        .buttonStyle(BouncyButtonStyle())
                    }

                    Text("Grown-ups can rename or remove players in the Grown-ups area.")
                        .font(Theme.font(13, .medium))
                        .foregroundStyle(Theme.softInk)
                        .multilineTextAlignment(.center)
                        .padding(.top, 6)
                }
                .padding(20)
            }
            .kidsBackground()
            .navigationTitle("Players")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.font(Theme.font(17, .bold))
                }
            }
        }
    }

    private var newPlayerForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("New player").font(Theme.font(19, .heavy)).foregroundStyle(Theme.ink)
            TextField("Name", text: $name)
                .font(Theme.font(20, .bold))
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .padding(12)
                .background(Theme.related, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            AvatarPicker(selection: $avatar)
            HStack(spacing: 10) {
                SoftButton(title: "Cancel") { adding = false }
                BigButton(title: "Add", color: Difficulty.easy.color) {
                    progress.addProfile(name: name, avatar: avatar)
                    adding = false
                    dismiss()
                }
            }
        }
        .padding(16)
        .card()
    }
}

struct AvatarPicker: View {
    @Binding var selection: String

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
            ForEach(Profile.avatars, id: \.self) { a in
                Button {
                    selection = a
                    Feedback.tap()
                } label: {
                    Text(a)
                        .font(.system(size: 30))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(selection == a ? Theme.selected : Theme.related, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(BouncyButtonStyle())
                .accessibilityAddTraits(selection == a ? .isSelected : [])
            }
        }
    }
}
