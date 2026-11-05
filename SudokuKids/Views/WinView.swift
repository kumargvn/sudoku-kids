import SwiftUI

struct WinView: View {
    let config: GameConfig
    let stars: Int
    let seconds: Int
    let mistakes: Int
    let hintsUsed: Int
    let onNewPuzzle: (() -> Void)?
    let onHome: () -> Void

    @State private var appeared = false

    private static let cheers = ["You did it!", "Amazing!", "Super solver!", "Brain power!", "Fantastic!"]
    @State private var cheer = WinView.cheers.randomElement() ?? "You did it!"

    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            ConfettiView()

            VStack(spacing: 16) {
                Text("🎉")
                    .font(.system(size: 64))
                Text(cheer)
                    .font(Theme.font(34, .heavy))
                    .foregroundStyle(Theme.ink)

                HStack(spacing: 8) {
                    ForEach(1...3, id: \.self) { n in
                        Image(systemName: n <= stars ? "star.fill" : "star")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(Theme.star)
                            .scaleEffect(appeared ? 1 : 0.1)
                            .animation(
                                .spring(response: 0.4, dampingFraction: 0.5).delay(Double(n) * 0.2),
                                value: appeared
                            )
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(stars) out of 3 stars")

                HStack(spacing: 18) {
                    ResultStat(icon: "stopwatch.fill", text: formatTime(seconds))
                    ResultStat(icon: "xmark.circle.fill", text: "\(mistakes)")
                    ResultStat(icon: "lightbulb.fill", text: "\(hintsUsed)")
                }

                Text(tip)
                    .font(Theme.font(15, .medium))
                    .foregroundStyle(Theme.softInk)
                    .multilineTextAlignment(.center)

                VStack(spacing: 10) {
                    if let onNewPuzzle {
                        Button(action: onNewPuzzle) {
                            Text("New puzzle")
                                .font(Theme.font(19, .heavy))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .foregroundStyle(.white)
                                .background(config.difficulty.color, in: Capsule())
                        }
                    }
                    Button(action: onHome) {
                        Text("Home")
                            .font(Theme.font(17, .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundStyle(Theme.entry)
                            .background(Theme.entry.opacity(0.12), in: Capsule())
                    }
                }
                .buttonStyle(BouncyButtonStyle())
            }
            .padding(24)
            .frame(maxWidth: 380)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
            .shadow(radius: 20)
            .padding(24)
            .scaleEffect(appeared ? 1 : 0.8)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: appeared)
        }
        .onAppear { appeared = true }
    }

    private var tip: String {
        switch stars {
        case 3: return "Perfect! Ready to try a harder level?"
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
            emoji: ["🎉", "⭐️", "🎈", "✨", "🌟", "🍭"].randomElement()!,
            x: .random(in: 0.02...0.98),
            size: .random(in: 18...34),
            spin: .random(in: -360...360),
            duration: .random(in: 2.2...4.0),
            delay: .random(in: 0...1.2)
        )
    }
    @State private var falling = false

    var body: some View {
        GeometryReader { geo in
            ForEach(pieces) { piece in
                Text(piece.emoji)
                    .font(.system(size: piece.size))
                    .rotationEffect(.degrees(falling ? piece.spin : 0))
                    .position(
                        x: piece.x * geo.size.width,
                        y: falling ? geo.size.height + 60 : -60
                    )
                    .animation(.easeIn(duration: piece.duration).delay(piece.delay), value: falling)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear { falling = true }
    }
}
