import SwiftUI

struct WinView: View {
    struct Action {
        let title: String
        let run: () -> Void
    }

    let config: GameConfig
    let stars: Int
    let seconds: Int
    let mistakes: Int
    let hintsUsed: Int
    let newTrophies: [Trophy]
    let primary: Action?
    let onHome: () -> Void

    @State private var appeared = false
    @State private var cheer = ["You did it!", "Amazing!", "Super solver!", "Brain power!", "Fantastic!"].randomElement() ?? "You did it!"

    init(config: GameConfig, stars: Int, seconds: Int, mistakes: Int, hintsUsed: Int,
         newTrophies: [Trophy], primary: Action?, onHome: @escaping () -> Void) {
        self.config = config
        self.stars = stars
        self.seconds = seconds
        self.mistakes = mistakes
        self.hintsUsed = hintsUsed
        self.newTrophies = newTrophies
        self.primary = primary
        self.onHome = onHome
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            ConfettiView()

            ScrollView {
                VStack(spacing: 14) {
                    Text("🎉").font(.system(size: 60))
                    Text(cheer)
                        .font(Theme.font(32, .heavy))
                        .foregroundStyle(Theme.ink)

                    HStack(spacing: 8) {
                        ForEach(1...3, id: \.self) { n in
                            Image(systemName: n <= stars ? "star.fill" : "star")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundStyle(Theme.star)
                                .scaleEffect(appeared ? 1 : 0.1)
                                .animation(.spring(response: 0.4, dampingFraction: 0.5).delay(Double(n) * 0.2), value: appeared)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(stars) out of 3 stars")

                    HStack(spacing: 18) {
                        ResultStat(icon: "stopwatch.fill", text: formatTime(seconds))
                        ResultStat(icon: "xmark.circle.fill", text: "\(mistakes)")
                        ResultStat(icon: "lightbulb.fill", text: "\(hintsUsed)")
                    }

                    if !newTrophies.isEmpty {
                        VStack(spacing: 8) {
                            Text(newTrophies.count == 1 ? "New trophy!" : "New trophies!")
                                .font(Theme.font(17, .heavy))
                                .foregroundStyle(Theme.ink)
                            ForEach(newTrophies) { trophy in
                                HStack(spacing: 10) {
                                    Text(trophy.emoji).font(.system(size: 30))
                                    Text(trophy.title).font(Theme.font(17, .bold)).foregroundStyle(Theme.ink)
                                    Spacer(minLength: 0)
                                }
                                .padding(10)
                                .background(Theme.star.opacity(0.18), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }
                        .onAppear { Feedback.trophy() }
                    }

                    Text(tip)
                        .font(Theme.font(15, .medium))
                        .foregroundStyle(Theme.softInk)
                        .multilineTextAlignment(.center)

                    VStack(spacing: 10) {
                        if let primary {
                            BigButton(title: primary.title, color: config.difficulty.color, action: primary.run)
                        }
                        SoftButton(title: "Home", action: onHome)
                    }
                }
                .padding(24)
                .frame(maxWidth: 380)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
                .shadow(radius: 20)
                .padding(24)
                .scaleEffect(appeared ? 1 : 0.85)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: appeared)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            .frame(maxHeight: .infinity)
        }
        .onAppear { appeared = true }
    }

    private var tip: String {
        switch stars {
        case 3: return "Perfect! Ready to try something harder?"
        case 2: return "Great job! Fewer hints next time for 3 stars."
        default: return "You finished it! Every puzzle makes your brain stronger."
        }
    }
}

private struct ResultStat: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text).monospacedDigit()
        }
        .font(Theme.font(17, .bold))
        .foregroundStyle(Theme.ink)
    }
}

struct ConfettiView: View {
    private struct Piece: Identifiable {
        let id: Int
        let emoji: String
        let x: CGFloat
        let size: CGFloat
        let spin: Double
        let duration: Double
        let delay: Double
    }

    @State private var pieces: [Piece] = (0..<45).map { n in
        Piece(
            id: n,
            emoji: ["🎉", "⭐️", "🎈", "✨", "🌟", "🍭"].randomElement() ?? "🎉",
            x: .random(in: 0.02...0.98),
            size: .random(in: 18...34),
            spin: .random(in: -360...360),
            duration: .random(in: 2.2...4.0),
            delay: .random(in: 0...1.2)
        )
    }
    @State private var falling = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            if !reduceMotion {
                ForEach(pieces) { piece in
                    Text(piece.emoji)
                        .font(.system(size: piece.size))
                        .rotationEffect(.degrees(falling ? piece.spin : 0))
                        .position(x: piece.x * geo.size.width, y: falling ? geo.size.height + 60 : -60)
                        .animation(.easeIn(duration: piece.duration).delay(piece.delay), value: falling)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear { falling = true }
    }
}
