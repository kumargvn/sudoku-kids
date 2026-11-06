import SwiftUI

struct AdventureView: View {
    @EnvironmentObject private var progress: ProgressStore

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 4) {
                    Text("🗺️ Adventure")
                        .font(Theme.font(30, .heavy))
                        .foregroundStyle(Theme.ink)
                    Text("Finish a level to open the next one. Collect all the stars!")
                        .font(Theme.font(15, .medium))
                        .foregroundStyle(Theme.softInk)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 6)

                ForEach(Array(Adventure.worlds.enumerated()), id: \.element.id) { index, world in
                    WorldCard(
                        world: world,
                        previous: index > 0 ? Adventure.worlds[index - 1] : nil
                    )
                }
            }
            .padding(20)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .kidsBackground()
        .navigationTitle("Adventure")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct WorldCard: View {
    @EnvironmentObject private var progress: ProgressStore
    let world: AdventureWorld
    let previous: AdventureWorld?

    private var isOpen: Bool { world.levels.first.map { progress.isUnlocked($0) } ?? false }
    private var doneCount: Int { world.levels.filter { progress.stars(for: $0) != nil }.count }
    private var starCount: Int { world.levels.compactMap { progress.stars(for: $0) }.reduce(0, +) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Text(world.emoji)
                    .font(.system(size: 40))
                    .frame(width: 62, height: 62)
                    .background(.white.opacity(0.3), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(world.title).font(Theme.font(22, .heavy))
                    Text(world.blurb).font(Theme.font(14, .semibold)).opacity(0.95)
                    Text("\(doneCount)/\(world.levels.count) levels · ⭐ \(starCount)/\(world.levels.count * 3)")
                        .font(Theme.font(13, .bold))
                        .opacity(0.9)
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(.white)

            if isOpen {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                    ForEach(world.levels) { level in
                        LevelBubble(level: level, world: world)
                    }
                }
            } else {
                Label("Finish \(previous?.title ?? "the last world") to open", systemImage: "lock.fill")
                    .font(Theme.font(15, .bold))
                    .foregroundStyle(.white)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(.black.opacity(0.15), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(16)
        .background(
            (isOpen ? world.color : Theme.locked).gradient,
            in: RoundedRectangle(cornerRadius: 26, style: .continuous)
        )
        .shadow(color: (isOpen ? world.color : .black).opacity(0.25), radius: 8, y: 4)
    }
}

private struct LevelBubble: View {
    @EnvironmentObject private var progress: ProgressStore
    let level: AdventureLevel
    let world: AdventureWorld

    var body: some View {
        let unlocked = progress.isUnlocked(level)
        let stars = progress.stars(for: level)
        let label = VStack(spacing: 2) {
            if unlocked {
                Text("\(level.number)")
                    .font(Theme.font(24, .heavy))
                    .foregroundStyle(world.color)
                Text(level.size.label)
                    .font(Theme.font(11, .bold))
                    .foregroundStyle(Theme.softInk)
                HStack(spacing: 1) {
                    ForEach(1...3, id: \.self) { n in
                        Image(systemName: n <= (stars ?? 0) ? "star.fill" : "star")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.star)
                    }
                }
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.locked)
                    .frame(height: 48)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Theme.card.opacity(unlocked ? 1 : 0.7), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

        if unlocked {
            NavigationLink(value: Route.game(.adventure(level))) { label }
                .buttonStyle(BouncyButtonStyle())
                .accessibilityLabel("Level \(level.number), \(level.size.label) \(level.difficulty.title), \(stars ?? 0) stars")
        } else {
            label.accessibilityLabel("Level \(level.number), locked")
        }
    }
}
