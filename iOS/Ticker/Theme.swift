import SwiftUI

/// Ticker's identity: deep teal backdrop with a hot coral accent for the
/// live running-cost counter. Distinct from every sibling app's palette
/// (soil-brown/sage Sprout, charcoal/volt-yellow Volt, slate/amber Beacon).
enum TKTheme {
    static let backdrop = Color(red: 0.043, green: 0.145, blue: 0.157)   // deep teal-black
    static let surface = Color(red: 0.071, green: 0.204, blue: 0.216)
    static let surfaceRaised = Color(red: 0.098, green: 0.263, blue: 0.278)
    static let ink = Color(red: 0.949, green: 0.965, blue: 0.961)
    static let inkFaded = Color(red: 0.949, green: 0.965, blue: 0.961).opacity(0.56)
    static let rule = Color.white.opacity(0.10)

    static let coral = Color(red: 0.980, green: 0.373, blue: 0.400)
    static let coralBright = Color(red: 1.0, green: 0.482, blue: 0.502)
    static let mint = Color(red: 0.412, green: 0.882, blue: 0.741)
    static let warning = Color(red: 0.945, green: 0.678, blue: 0.318)

    static let displayFont = Font.system(size: 52, weight: .bold, design: .rounded).monospacedDigit()
    static let titleFont = Font.system(.title2, design: .rounded).weight(.bold)
    static let headlineFont = Font.system(.headline, design: .rounded).weight(.semibold)
}

struct DismissKeyboardOnTap: ViewModifier {
    func body(content: Content) -> some View {
        content.simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            }
        )
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTap())
    }
}

enum Haptics {
    static var enabled: Bool = true

    static func light() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func success() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
