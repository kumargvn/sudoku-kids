import SwiftUI

enum Theme {
    static let ink = Color(red: 0.16, green: 0.19, blue: 0.36)
    static let softInk = Color(red: 0.40, green: 0.43, blue: 0.58)
    static let card = Color.white
    static let entry = Color(red: 0.13, green: 0.43, blue: 0.93)
    static let mistake = Color(red: 0.91, green: 0.24, blue: 0.31)
    static let selected = Color(red: 1.00, green: 0.81, blue: 0.33)
    static let related = Color(red: 0.92, green: 0.94, blue: 1.00)
    static let sameNumber = Color(red: 0.76, green: 0.85, blue: 1.00)
    static let hintFocus = Color(red: 1.00, green: 0.95, blue: 0.74)
    static let keyCell = Color(red: 0.62, green: 0.78, blue: 1.00)
    static let hintTarget = Color(red: 0.55, green: 0.90, blue: 0.62)
    static let star = Color(red: 1.00, green: 0.76, blue: 0.11)
    static let locked = Color(red: 0.80, green: 0.82, blue: 0.88)

    static let background = LinearGradient(
        colors: [Color(red: 1.00, green: 0.96, blue: 0.86), Color(red: 0.87, green: 0.94, blue: 1.00)],
        startPoint: .top,
        endPoint: .bottom
    )

    static func font(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

extension Difficulty {
    var color: Color {
        switch self {
        case .easy: return Color(red: 0.30, green: 0.75, blue: 0.45)
        case .medium: return Color(red: 0.24, green: 0.58, blue: 0.95)
        case .hard: return Color(red: 0.98, green: 0.55, blue: 0.20)
        case .expert: return Color(red: 0.62, green: 0.36, blue: 0.90)
        }
    }
}

extension AdventureWorld {
    var color: Color {
        switch id {
        case "forest": return Color(red: 0.30, green: 0.72, blue: 0.42)
        case "ocean": return Color(red: 0.16, green: 0.62, blue: 0.86)
        case "garden": return Color(red: 0.93, green: 0.36, blue: 0.52)
        case "space": return Color(red: 0.45, green: 0.36, blue: 0.86)
        default: return Color(red: 0.95, green: 0.52, blue: 0.18)
        }
    }
}

/// Big, squishy, kid-friendly button feel.
struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// A white rounded card.
struct CardBackground: ViewModifier {
    var radius: CGFloat = 22

    func body(content: Content) -> some View {
        content
            .background(Theme.card, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
    }
}

extension View {
    func card(radius: CGFloat = 22) -> some View { modifier(CardBackground(radius: radius)) }

    /// The screen background used everywhere.
    func kidsBackground() -> some View { background(Theme.background.ignoresSafeArea()) }
}

func formatTime(_ seconds: Int) -> String {
    String(format: "%d:%02d", seconds / 60, seconds % 60)
}

func formatMinutes(_ seconds: Int) -> String {
    let minutes = seconds / 60
    if minutes < 60 { return "\(minutes) min" }
    return "\(minutes / 60) h \(minutes % 60) min"
}

/// Section heading used on list screens.
struct SectionTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(Theme.font(22, .heavy))
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 6)
    }
}
