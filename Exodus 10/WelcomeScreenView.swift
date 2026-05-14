import SwiftUI

struct WelcomeScreenView: View {
    let onSelectBeginner: () -> Void
    let onSelectMaestro: () -> Void

    @State private var showOverview: Bool = false

    var body: some View {
        GeometryReader { proxy in
            let tileWidth = (proxy.size.width - 48) * 0.9
            let tileHeight = tileWidth * (605.0 / 832.0)
            let tileCornerRadius = min(24, tileWidth * 0.08)
            let tileCenterY = proxy.size.height * 0.25

            ZStack {
                FullScreenElephantBackground()
                    .ignoresSafeArea()

                Color.black.opacity(0.42)
                    .ignoresSafeArea()

                // Elephant surround with gold border around logo tile
                ElephantWindowView(
                    canvasSize: proxy.size,
                    highlightWidth: tileWidth,
                    highlightHeight: tileHeight,
                    highlightCenter: CGPoint(x: proxy.size.width / 2, y: tileCenterY),
                    highlightCornerRadius: tileCornerRadius
                )
                .allowsHitTesting(false)

                // REFRETLOGOSET tile in the window
                ZStack {
                    Image("REFRETLOGOSET")
                        .resizable()
                        .scaledToFill()
                        .scaleEffect(x: 1.15, y: 1.0, anchor: .center)
                        .frame(width: tileWidth, height: tileHeight)
                        .clipped()
                        .clipShape(HighlightWindowShape(cornerRadius: tileCornerRadius))

                    HighlightWindowGoldBorder(
                        width: tileWidth,
                        height: tileHeight,
                        cornerRadius: tileCornerRadius
                    )
                }
                .position(x: proxy.size.width / 2, y: tileCenterY)
                .allowsHitTesting(false)

                // Gold perimeter piping
                GoldPipingBorder(bottomInset: 0)

                // Bottom content: console buttons + learn link
                VStack(spacing: 0) {
                    Spacer()

                    VStack(spacing: 16) {
                        WelcomeConsoleButton(
                            title: "BEGINNER CONSOLE",
                            subtitle: "6-button note training",
                            action: onSelectBeginner
                        )
                        .accessibilityLabel(A11y.Welcome.beginnerButton)
                        .accessibilityHint(A11y.Welcome.beginnerHint)
                        WelcomeConsoleButton(
                            title: "MAESTRO CONSOLE",
                            subtitle: "Memory-based recall",
                            action: onSelectMaestro
                        )
                        .accessibilityLabel(A11y.Welcome.maestroButton)
                        .accessibilityHint(A11y.Welcome.maestroHint)

                        Button(action: { showOverview = true }) {
                            HStack(spacing: 9) {
                                Text("LEARN THE GAME")
                                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                                    .tracking(1.5)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 17, weight: .bold))
                            }
                            .foregroundColor(.goldBorderMid)
                            .padding(.vertical, 15)
                        }
                        .accessibilityLabel(A11y.Welcome.overviewButton)
                        .accessibilityHint(A11y.Welcome.overviewHint)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, max(proxy.safeAreaInsets.bottom + 24, 40))
                }
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showOverview) {
            OverviewPageView()
        }
    }
}

private struct WelcomeConsoleButton: View {
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Text(title)
                    .font(.system(size: 23, weight: .black, design: .monospaced))
                    .tracking(1)
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 17, weight: .regular, design: .monospaced))
                    .foregroundColor(.white.opacity(0.55))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Color.black.opacity(0.65))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.goldBorderMid, .goldBorderDark, .goldBorderLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
        }
    }
}
