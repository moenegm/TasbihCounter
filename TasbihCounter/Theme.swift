import SwiftUI

// MARK: - Counter colors

enum ThemeColor: String, CaseIterable, Identifiable {
    case black, blue, green, maroon, purple, white, pink, gold
    var id: String { rawValue }
    var name: String { rawValue.capitalized }

    var color: Color {
        switch self {
        case .black:  return Color(white: 0.15)
        case .blue:   return Color(red: 42/255,  green: 59/255,  blue: 140/255)
        case .green:  return Color(red: 30/255,  green: 82/255,  blue: 62/255)
        case .maroon: return Color(red: 105/255, green: 30/255,  blue: 38/255)
        case .purple: return Color(red: 88/255,  green: 50/255,  blue: 130/255)
        case .white:  return Color(red: 0.93, green: 0.91, blue: 0.89)
        case .pink:   return Color(red: 214/255, green: 72/255,  blue: 128/255)
        case .gold:   return Color(red: 0.82, green: 0.64, blue: 0.22)
        }
    }

    // Icon/text color on top of the button
    var foreground: Color { self == .white ? .black : .white }
    // Used for the selection ring in Settings
    var accent: Color { (self == .black || self == .white) ? .gray : color }

    // Clicker images exist for every color except gold
    var hasClicker: Bool { self != .gold }
    var clickerImage: String { "clicker-" + (hasClicker ? rawValue : "black") }
}

enum CounterStyle: String, CaseIterable, Identifiable {
    case button, clicker
    var id: String { rawValue }
    var name: String { self == .button ? "Button" : "Clicker" }
}

enum Appearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var name: String { rawValue.capitalized }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

let buttonIcons = [
    "hand.tap.fill", "hand.point.up.fill", "moon.stars.fill", "star.fill",
    "sparkles", "plus", "heart.fill", "circle.fill"
]

// MARK: - Arabic font (Noto Naskh Arabic, bundled with the app)

func arabicFont(_ size: CGFloat) -> Font {
    .custom("NotoNaskhArabic-Bold", size: size)
}

// MARK: - Gold trim style, matching the clicker

enum Gold {
    static let light = Color(red: 242/255, green: 215/255, blue: 140/255)
    static let mid   = Color(red: 201/255, green: 151/255, blue: 58/255)
    static let deep  = Color(red: 142/255, green: 100/255, blue: 32/255)

    static var gradient: LinearGradient {
        LinearGradient(colors: [light, mid, deep], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // Gold text that stays readable on dark and light glass
    static func text(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? light : Color(red: 154/255, green: 114/255, blue: 36/255)
    }
}

// Frosted glass with a thin gold edge. Dark glass on dark backgrounds, light glass on light ones.
struct GoldGlass<S: InsettableShape>: ViewModifier {
    var shape: S
    var lineWidth: CGFloat
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    shape.fill(.ultraThinMaterial)
                    shape.fill(scheme == .dark
                               ? Color(red: 0.04, green: 0.05, blue: 0.11).opacity(0.45)
                               : Color.white.opacity(0.5))
                }
            }
            .overlay {
                shape.strokeBorder(scheme == .dark ? Gold.mid.opacity(0.95) : Gold.deep.opacity(0.9),
                                   lineWidth: lineWidth)
            }
            .shadow(color: .black.opacity(scheme == .dark ? 0.25 : 0.12), radius: 10, y: 4)
    }
}

extension View {
    func goldGlass<S: InsettableShape>(_ shape: S, lineWidth: CGFloat = 1.5) -> some View {
        modifier(GoldGlass(shape: shape, lineWidth: lineWidth))
    }
}

// The small gold preset name at the top of the card
struct GoldLabel: View {
    var text: String
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Text(text)
            .font(.footnote.weight(.bold))
            .tracking(0.5)
            .foregroundStyle(Gold.text(scheme))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}
