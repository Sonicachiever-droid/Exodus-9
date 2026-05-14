import SwiftUI

struct OverviewPageView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            FullScreenElephantBackground()
                .ignoresSafeArea()

            Color.black.opacity(0.55)
                .ignoresSafeArea()

            GoldPipingBorder(bottomInset: 0)

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {

                    // Header
                    VStack(alignment: .center, spacing: 6) {
                        Text("REFRET")
                            .font(.system(size: 68, weight: .black, design: .monospaced))
                            .foregroundColor(Color(red: 0.95, green: 0.82, blue: 0.47))
                            .tracking(4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    Divider()
                        .background(Color(red: 0.95, green: 0.82, blue: 0.47).opacity(0.5))

                    // Section: What Is This?
                    OverviewSection(title: "WHAT IS THIS?") {
                        Text("ReFret is a fretboard training app for guitar players. It teaches you to identify notes by string and fret position across the entire neck — from open strings to fret 19.")
                    }

                    // Section: Two Consoles
                    OverviewSection(title: "TWO CONSOLES") {
                        VStack(alignment: .leading, spacing: 14) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("BEGINNER CONSOLE")
                                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                    .foregroundColor(Color(red: 0.95, green: 0.82, blue: 0.47))
                                Text("Six answer buttons, one per string, each showing a note name. Tap the correct note for the highlighted string. Notes are revealed progressively before each round begins.")
                                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.88))
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("MAESTRO CONSOLE")
                                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                    .foregroundColor(Color(red: 0.95, green: 0.82, blue: 0.47))
                                Text("No hints. Two answer buttons show note names — identify the correct one from memory. Wrong answers restart the current fret. A more demanding test of recall.")
                                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.88))
                            }
                        }
                    }

                    // Section: Scoring
                    OverviewSection(title: "SCORING") {
                        Text("Correct answers earn dollars. Beginner earns $1 per correct note. Maestro earns $2. Wrong answers do not cost you — the fret simply restarts. Your wallet accumulates across the session. Maintain a streak of correct answers to win multipliers and earn even more points.")
                    }

                    // Section: Rounds & Frets
                    OverviewSection(title: "ROUNDS & FRETS") {
                        Text("One round covers all strings on one fret. Complete a round to advance to the next fret. Fret 0 is open strings. The game moves through all 12 frets by default, or up to fret 19 with High Frets enabled in PLAY settings.")
                    }

                    // Section: Settings
                    OverviewSection(title: "SETTINGS") {
                        Text("Open MENU during play to access four tabs: HOME (wallet, balance, purchasable upgrades like High Frets and Landscape Mode, console skins), PLAY (starting fret, repetitions, direction, progression, high frets), GUIDE (quick reference), and AUDIO (guitar tone, tempo).")
                    }

                    // Footer
                    Text("[PLACEHOLDER — tagline / brand statement]")
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundColor(.white.opacity(0.35))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Text("CLOSE")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(red: 0.95, green: 0.82, blue: 0.47))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(red: 0.95, green: 0.82, blue: 0.47).opacity(0.5), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 20)
                    .padding(.top, 16)
                }
                Spacer()
            }
        }
    }
}

private struct OverviewSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .black, design: .monospaced))
                .foregroundColor(Color(red: 0.95, green: 0.82, blue: 0.47))
                .tracking(2)

            content()
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.88))
                .lineSpacing(5)
        }
    }
}
