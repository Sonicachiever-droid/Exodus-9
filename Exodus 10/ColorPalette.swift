import SwiftUI

// MARK: - Color Palette

extension Color {

    // MARK: - Classic (Gold) Skin — plate/button gradient, 8× across 6 files
    static let goldLight   = Color(red: 0.98, green: 0.90, blue: 0.66)
    static let goldMid     = Color(red: 0.90, green: 0.74, blue: 0.40)
    static let goldDark    = Color(red: 0.73, green: 0.55, blue: 0.26)
    static let goldMidtone = Color(red: 0.94, green: 0.82, blue: 0.53)

    // MARK: - Gold Border — piping/border gradient, 4× across 4 files
    static let goldBorderLight = Color(red: 0.97, green: 0.85, blue: 0.50)
    static let goldBorderMid   = Color(red: 0.95, green: 0.82, blue: 0.47)
    static let goldBorderDark  = Color(red: 0.78, green: 0.60, blue: 0.22)

    // MARK: - Chrome (Tweed) Skin — plate/button gradient, 4× across 3 files
    static let chromeLight  = Color(red: 0.95, green: 0.95, blue: 0.95)
    static let chromeMid    = Color(red: 0.60, green: 0.60, blue: 0.60)
    static let chromeDark   = Color(red: 0.45, green: 0.45, blue: 0.45)
    static let chromeShadow = Color(red: 0.25, green: 0.25, blue: 0.25)
    static let chromeBase   = Color(red: 0.55, green: 0.55, blue: 0.55)

    // MARK: - Screen / Display — dark CRT background, 3× across 3 files
    static let screenDark    = Color(red: 0.08, green: 0.08, blue: 0.10)
    static let screenDarkAlt = Color(red: 0.18, green: 0.18, blue: 0.20)
    static let screenInner   = Color(red: 0.07, green: 0.07, blue: 0.08)

    // MARK: - Screen Glow — incandescent CRT warmth
    static let glowWarm   = Color(red: 1.00, green: 0.96, blue: 0.70)
    static let glowOrange = Color(red: 1.00, green: 0.78, blue: 0.12)
    static let glowDeep   = Color(red: 1.00, green: 0.56, blue: 0.00)
    static let glowBrown  = Color(red: 0.28, green: 0.12, blue: 0.00)

    // MARK: - Answer Feedback
    static let feedbackGreenFill   = Color(red: 0.64, green: 0.98, blue: 0.70)
    static let feedbackRedFill     = Color(red: 1.00, green: 0.62, blue: 0.58)
    static let feedbackRedStroke   = Color(red: 0.48, green: 0.06, blue: 0.06)
    static let feedbackGreenStroke = Color(red: 0.04, green: 0.42, blue: 0.12)

    // MARK: - Highlight Accent
    static let highlightBlue = Color(red: 0.28, green: 0.70, blue: 1.00)

    // MARK: - Wound (Brass) Guitar Strings — E / A / D
    static let brassStringLight  = Color(red: 0.96, green: 0.94, blue: 0.88)  // cream highlight
    static let brassStringMid    = Color(red: 0.82, green: 0.69, blue: 0.47)  // golden mid
    static let brassStringDark   = Color(red: 0.65, green: 0.50, blue: 0.30)  // dark amber
    static let brassStringWarm   = Color(red: 0.85, green: 0.75, blue: 0.60)  // warm wrap highlight
}
