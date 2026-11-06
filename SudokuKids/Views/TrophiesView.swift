import SwiftUI

struct TrophiesView: View {
    @EnvironmentObject private var progress: ProgressStore

    var body: some View {
        let earned = progress.stats.trophies
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("🏆 Trophies")
                        .font(Theme.font(30, .heavy))
                        .foregroundStyle(Theme.ink)
                    Text("\(earned.count) of \(Trophies.all.count) collected")
                        .font(Theme.font(16, .semibold))
                        .foregroundStyle(Theme.softInk)
                }
                .padding(.top, 6)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                    ForEach(Trophies.all) { trophy in
                        let has = earned.contains(trophy.id)
                        VStack(spacing: 6) {
                            Text(has ? trophy.emoji : "❔")
                                .font(.system(size: 42))
                                .grayscale(has ? 0 : 1)
                                .opacity(has ? 1 : 0.5)
                            Text(trophy.title)
                                .font(Theme.font(16, .heavy))
                                .foregroundStyle(has ? Theme.ink : Theme.softInk)
                                .multilineTextAlignment(.center)
                            Text(trophy.goal)
                                .font(Theme.font(12, .semibold))
                                .foregroundStyle(Theme.softInk)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, minHeight: 150)
                        .padding(10)
                        .background(has ? Theme.star.opacity(0.16) : Theme.card,
                                    in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(has ? Theme.star : .clear, lineWidth: 2))
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(trophy.title), \(has ? "earned" : "not earned yet"). \(trophy.goal)")
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .kidsBackground()
        .navigationTitle("Trophies")
        .navigationBarTitleDisplayMode(.inline)
    }
}
