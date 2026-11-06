import SwiftUI

/// Keeps grown-up settings away from young kids (Apple requires this for the Kids category).
struct ParentGateView: View {
    let onPass: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var a = Int.random(in: 6...9)
    @State private var b = Int.random(in: 6...9)
    @State private var answer = ""
    @State private var wrong = false
    @FocusState private var focused: Bool

    init(onPass: @escaping () -> Void) {
        self.onPass = onPass
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Theme.entry)
                Text("Grown-ups only")
                    .font(Theme.font(26, .heavy))
                    .foregroundStyle(Theme.ink)
                Text("To continue, type the answer:")
                    .font(Theme.font(16, .medium))
                    .foregroundStyle(Theme.softInk)
                Text("\(a) × \(b) = ?")
                    .font(Theme.font(40, .heavy))
                    .foregroundStyle(Theme.ink)
                TextField("Answer", text: $answer)
                    .keyboardType(.numberPad)
                    .font(Theme.font(28, .bold))
                    .multilineTextAlignment(.center)
                    .padding(12)
                    .frame(maxWidth: 200)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .focused($focused)
                if wrong {
                    Text("That's not it. Try this one.")
                        .font(Theme.font(15, .semibold))
                        .foregroundStyle(Theme.mistake)
                }
                BigButton(title: "Continue", color: Theme.entry) { check() }
                    .frame(maxWidth: 280)
                Spacer()
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .kidsBackground()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { focused = true }
        }
    }

    private func check() {
        if Int(answer.trimmingCharacters(in: .whitespaces)) == a * b {
            onPass()
            dismiss()
        } else {
            wrong = true
            answer = ""
            a = Int.random(in: 6...9)
            b = Int.random(in: 6...9)
        }
    }
}

struct ParentAreaView: View {
    @EnvironmentObject private var progress: ProgressStore
    @Environment(\.dismiss) private var dismiss
    @State private var renaming: Profile? = nil
    @State private var newName = ""
    @State private var newAvatar = Profile.avatars[0]
    @State private var confirmDelete: Profile? = nil
    @State private var confirmReset: Profile? = nil

    private let breakOptions = [0, 15, 30, 45, 60]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(progress.profiles) { profile in
                        PlayerReport(profile: profile)
                            .swipeActions {
                                if progress.profiles.count > 1 {
                                    Button("Remove", role: .destructive) { confirmDelete = profile }
                                }
                                Button("Reset") { confirmReset = profile }.tint(.orange)
                                Button("Edit") {
                                    renaming = profile
                                    newName = profile.name
                                    newAvatar = profile.avatar
                                }
                                .tint(Theme.entry)
                            }
                    }
                } header: {
                    Text("Players")
                } footer: {
                    Text("Swipe left on a player to edit, reset or remove them.")
                }

                Section {
                    Picker("Break reminder", selection: $progress.settings.breakReminderMinutes) {
                        ForEach(breakOptions, id: \.self) { minutes in
                            Text(minutes == 0 ? "Off" : "Every \(minutes) min").tag(minutes)
                        }
                    }
                } header: {
                    Text("Play time")
                } footer: {
                    Text("Shows a friendly \"time for a break\" message after this much play each day.")
                }

                Section("About Sudoku Kids") {
                    Label("Free. No ads and no purchases.", systemImage: "gift.fill")
                    Label("No accounts. Nothing is collected or shared.", systemImage: "hand.raised.fill")
                    Label("All progress stays on this device.", systemImage: "iphone")
                }
            }
            .navigationTitle("Grown-ups")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $renaming) { profile in
                NavigationStack {
                    VStack(spacing: 16) {
                        TextField("Name", text: $newName)
                            .font(Theme.font(20, .bold))
                            .padding(12)
                            .background(Theme.related, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        AvatarPicker(selection: $newAvatar)
                        Spacer()
                    }
                    .padding(20)
                    .navigationTitle("Edit player")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button("Cancel") { renaming = nil } }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                progress.rename(profile.id, to: newName, avatar: newAvatar)
                                renaming = nil
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
            .confirmationDialog("Remove \(confirmDelete?.name ?? "player")?", isPresented: Binding(
                get: { confirmDelete != nil }, set: { if !$0 { confirmDelete = nil } }
            ), titleVisibility: .visible) {
                Button("Remove player and progress", role: .destructive) {
                    if let p = confirmDelete { progress.deleteProfile(p.id) }
                    confirmDelete = nil
                }
            }
            .confirmationDialog("Reset \(confirmReset?.name ?? "player")'s progress?", isPresented: Binding(
                get: { confirmReset != nil }, set: { if !$0 { confirmReset = nil } }
            ), titleVisibility: .visible) {
                Button("Reset stars, trophies and stats", role: .destructive) {
                    if let p = confirmReset { progress.resetProgress(p.id) }
                    confirmReset = nil
                }
            }
        }
    }
}

private struct PlayerReport: View {
    @EnvironmentObject private var progress: ProgressStore
    let profile: Profile

    var body: some View {
        let s = profile.stats
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(profile.avatar).font(.system(size: 28))
                Text(profile.name).font(Theme.font(18, .heavy))
                Spacer()
                Text("⭐ \(s.totalStars)").font(Theme.font(15, .bold))
            }
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 4) {
                GridRow {
                    Text("Puzzles solved").foregroundStyle(.secondary)
                    Text("\(s.totalWins)  (4×4: \(s.winCount(size: .four)), 6×6: \(s.winCount(size: .six)), 9×9: \(s.winCount(size: .nine)))")
                }
                GridRow {
                    Text("Hardest level").foregroundStyle(.secondary)
                    Text(Difficulty.allCases.last { s.winCount(difficulty: $0) > 0 }?.title ?? "None yet")
                }
                GridRow {
                    Text("Lessons learned").foregroundStyle(.secondary)
                    Text("\(s.techniquesLearned.count) of \(Technique.allCases.count)")
                }
                GridRow {
                    Text("Adventure").foregroundStyle(.secondary)
                    Text("\(s.adventureStars.count) of \(Adventure.allLevels.count) levels")
                }
                GridRow {
                    Text("Trophies").foregroundStyle(.secondary)
                    Text("\(s.trophies.count) of \(Trophies.all.count)")
                }
                GridRow {
                    Text("Played today").foregroundStyle(.secondary)
                    Text(formatMinutes(progress.playedToday(for: profile)))
                }
                GridRow {
                    Text("Last 7 days").foregroundStyle(.secondary)
                    Text(formatMinutes(progress.playedThisWeek(for: profile)))
                }
            }
            .font(Theme.font(14, .medium))
        }
        .padding(.vertical, 4)
    }
}
