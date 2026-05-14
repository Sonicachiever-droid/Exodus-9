import SwiftUI

// MARK: - String Line Overlay

private func safeCGFloat(_ value: CGFloat) -> CGFloat {
    value.isFinite ? max(0, value) : 0
}

struct StringLineOverlay: View {
    let neckWidth: CGFloat
    let horizontalPadding: CGFloat
    let stringTopY: CGFloat
    private let bottomClearance: CGFloat = 10

    var body: some View {
        GeometryReader { geo in
            let clippedTopY = min(max(stringTopY, 0), geo.size.height)
            let clippedBottomY = max(clippedTopY, geo.size.height - bottomClearance)
            let clippedHeight = max(clippedBottomY - clippedTopY, 0)
            let grooveCenters = GuitarStringLayout.stringCenters(containerWidth: geo.size.width, neckWidth: neckWidth)

            ZStack {
                ForEach(0..<GuitarStringLayout.totalStrings, id: \.self) { index in
                    let isBass = index < 3  // indices 0-2 = strings 6/5/4 (E A D)
                    let stringWidth = isBass ? 2.8 - CGFloat(index) * 0.35 : 1.4
                    let centerX = grooveCenters[index]
                    let midY = clippedTopY + clippedHeight / 2

                    // Brass edge lines — one hair-thin black line on each side
                    if isBass {
                        Rectangle()
                            .fill(Color.black.opacity(0.55))
                            .frame(width: 0.5, height: clippedHeight)
                            .position(x: centerX - stringWidth / 2 - 0.25, y: midY)
                        Rectangle()
                            .fill(Color.black.opacity(0.55))
                            .frame(width: 0.5, height: clippedHeight)
                            .position(x: centerX + stringWidth / 2 + 0.25, y: midY)
                    }

                    Rectangle()
                        .fill(
                            isBass
                            ? LinearGradient(
                                colors: [
                                    .brassStringLight,
                                    .brassStringMid,
                                    .brassStringDark,
                                    .brassStringWarm
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            : LinearGradient(
                                colors: [
                                    Color(red: 0.88, green: 0.88, blue: 0.84),
                                    Color(red: 0.62, green: 0.62, blue: 0.58),
                                    Color(red: 0.42, green: 0.42, blue: 0.38)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: stringWidth, height: clippedHeight)
                        .position(x: centerX, y: midY)
                }
            }
            .frame(width: safeCGFloat(geo.size.width), height: safeCGFloat(geo.size.height))
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Mini TV Frame

struct MiniTVFrame: View {
    let text: String
    let width: CGFloat
    let height: CGFloat
    let fontScale: CGFloat
    var isDarkScreen: Bool = false
    var glowTint: Color? = nil
    var hitTestingEnabled: Bool = false
    var consoleSkin: ConsoleSkin = .classic

    init(text: String, width: CGFloat, height: CGFloat, fontScale: CGFloat, isDarkScreen: Bool = false, glowTint: Color? = nil, hitTestingEnabled: Bool = false, consoleSkin: ConsoleSkin = .classic) {
        self.text = text
        self.width = width
        self.height = height
        self.fontScale = fontScale
        self.isDarkScreen = isDarkScreen
        self.glowTint = glowTint
        self.hitTestingEnabled = hitTestingEnabled
        self.consoleSkin = consoleSkin
    }

    var body: some View {
        let bezelWidth = width + UIConstants.miniTVBezelInsetW
        let bezelHeight = height + UIConstants.miniTVBezelInsetH

        return ZStack {
            RoundedRectangle(cornerRadius: UIConstants.consoleFrameRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: consoleSkin == .tweed
                            ? [Color(red: 0.96, green: 0.96, blue: 0.96), Color(red: 0.88, green: 0.88, blue: 0.88)]
                            : [.screenDark, .screenDarkAlt],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.6), radius: 8, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: UIConstants.consoleFrameRadius, style: .continuous)
                        .stroke(consoleSkin == .tweed ? Color.white.opacity(0.6) : Color.white.opacity(0.08), lineWidth: 1)
                )

            RoundedRectangle(cornerRadius: UIConstants.consoleInnerBorderRadius, style: .continuous)
                .stroke(consoleSkin == .tweed ? Color.white.opacity(0.55) : Color.black.opacity(0.65), lineWidth: 3)
                .padding(UIConstants.consoleFramePadding)

            Group {
                if isDarkScreen {
                    RoundedRectangle(cornerRadius: UIConstants.consoleContentRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.black.opacity(0.95), .screenInner, Color.black.opacity(0.95)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .padding(8)
                } else {
                    RoundedRectangle(cornerRadius: UIConstants.consoleContentRadius, style: .continuous)
                        .fill(
                            RadialGradient(
                                gradient: Gradient(stops: [
                                    .init(color: Color(white: 1.0, opacity: 0.85), location: 0.0),
                                    .init(color: .glowWarm, location: 0.08),
                                    .init(color: .glowOrange, location: 0.28),
                                    .init(color: .glowDeep, location: 0.40),
                                    .init(color: .glowBrown, location: 1.0)
                                ]),
                                center: .center,
                                startRadius: 2,
                                endRadius: 130
                            )
                        )
                        .padding(8)
                }
            }


            RoundedRectangle(cornerRadius: UIConstants.consoleInnerFrameRadius, style: .continuous)
                .fill(Color.clear)
                .padding(UIConstants.consoleContentPadding)

            Text(text.prefix(1).uppercased() + text.dropFirst())
                .font(.system(size: max(height * 0.78 * fontScale, 14), weight: .black, design: .default))
                .fontWidth(.condensed)
                .kerning(0.9)
                .allowsTightening(true)
                .foregroundColor(isDarkScreen ? .white : .black)
                .minimumScaleFactor(0.45)
                .padding(.horizontal, UIConstants.consoleContentPadding)
        }
        .frame(width: bezelWidth, height: bezelHeight)
        .overlay {
            if let glowTint {
                RoundedRectangle(cornerRadius: UIConstants.consoleFrameRadius, style: .continuous)
                    .stroke(glowTint.opacity(0.78), lineWidth: 1.2)
                    .padding(UIConstants.consoleFramePadding)
                    .shadow(color: glowTint.opacity(0.42), radius: 10)
            }
        }
        .allowsHitTesting(hitTestingEnabled)
    }
}

// MARK: - Screw Head View

struct ScrewHeadView: View {
    let size: CGFloat
    var consoleSkin: ConsoleSkin = .classic

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: consoleSkin == .tweed ? [
                            .chromeLight, .chromeBase
                        ] : [
                            .goldLight, .goldDark
                        ],
                        center: UnitPoint(x: 0.3, y: 0.25),
                        startRadius: size * 0.05,
                        endRadius: size * 0.7
                    )
                )
            Circle()
                .stroke(Color.black.opacity(0.35), lineWidth: 0.6)
            Rectangle()
                .fill(Color.black.opacity(0.45))
                .frame(width: safeCGFloat(size * 0.55), height: 0.8)
                .rotationEffect(.degrees(-12))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Thumb Button View

struct ThumbButtonView: View {
    let diameter: CGFloat
    let label: String
    let state: ThumbGlowState
    var consoleSkin: ConsoleSkin = .classic

    private var glowStops: [Gradient.Stop] {
        switch state {
        case .neutral:
            if consoleSkin == .tweed {
                return [
                    .init(color: Color(white: 1.0, opacity: 1.0), location: 0.0),
                    .init(color: Color(white: 1.0, opacity: 1.0), location: 0.12),
                    .init(color: .chromeLight, location: 0.34),
                    .init(color: .chromeMid, location: 0.54),
                    .init(color: .chromeShadow, location: 1.0)
                ]
            } else {
                return [
                    .init(color: Color(white: 1.0, opacity: 1.0), location: 0.0),
                    .init(color: Color(white: 1.0, opacity: 1.0), location: 0.12),
                    .init(color: .glowWarm, location: 0.34),
                    .init(color: .glowOrange, location: 0.54),
                    .init(color: .glowBrown, location: 1.0)
                ]
            }
        case .orange:
            return [
                .init(color: Color(white: 1.0, opacity: 1.0), location: 0.0),
                .init(color: Color(white: 1.0, opacity: 1.0), location: 0.12),
                .init(color: Color(red: 1.0, green: 0.84, blue: 0.38), location: 0.34),
                .init(color: Color(red: 1.0, green: 0.58, blue: 0.04), location: 0.54),
                .init(color: Color(red: 0.42, green: 0.17, blue: 0.00), location: 1.0)
            ]
        case .green:
            return [
                .init(color: Color(white: 1.0, opacity: 1.0), location: 0.0),
                .init(color: Color(white: 1.0, opacity: 1.0), location: 0.12),
                .init(color: Color(red: 0.66, green: 1.0, blue: 0.72), location: 0.34),
                .init(color: Color(red: 0.12, green: 0.84, blue: 0.22), location: 0.54),
                .init(color: Color(red: 0.0, green: 0.32, blue: 0.08), location: 1.0)
            ]
        case .red:
            return [
                .init(color: Color(white: 1.0, opacity: 1.0), location: 0.0),
                .init(color: Color(white: 1.0, opacity: 1.0), location: 0.12),
                .init(color: Color(red: 1.0, green: 0.58, blue: 0.46), location: 0.34),
                .init(color: Color(red: 0.82, green: 0.14, blue: 0.07), location: 0.54),
                .init(color: Color(red: 0.34, green: 0.01, blue: 0.01), location: 1.0)
            ]
        }
    }

    var body: some View {
        let bezel = diameter
        let ringOuter = diameter * 0.84
        let ringInner = diameter * 0.78
        let plunger = diameter * 0.50
        let screwOrbit = diameter * 0.39
        let screwSize = max(diameter * 0.085, 7)

        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: consoleSkin == .tweed ? [
                                .white, .chromeLight, .chromeBase, .chromeShadow, Color(red: 0.65, green: 0.65, blue: 0.65)
                            ] : [
                                .goldLight, .goldMid, .goldDark, .goldMidtone
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.45), Color.black.opacity(0.45)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.4
                            )
                    )
                    .shadow(color: .black.opacity(0.45), radius: 8, x: 0, y: 4)
                    .frame(width: bezel, height: bezel)

                Circle()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: ringMetalStops),
                            center: .center
                        ),
                        lineWidth: max(diameter * 0.085, 6)
                    )
                    .frame(width: ringOuter, height: ringOuter)

                Circle()
                    .stroke(
                        RadialGradient(
                            gradient: Gradient(stops: glowStops),
                            center: .center,
                            startRadius: ringInner * 0.02,
                            endRadius: ringInner * 0.65
                        )
                        .opacity(1.0),
                        lineWidth: max(diameter * 0.165, 12)
                    )
                    .frame(width: ringInner, height: ringInner)
                    .shadow(color: .white.opacity(0.62), radius: 6)
                    .shadow(color: ringShadowColor.opacity(0.95), radius: 16)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.75), lineWidth: max(diameter * 0.02, 1.6))
                            .frame(width: ringInner * 0.88, height: ringInner * 0.88)
                            .blur(radius: 0.25)
                    )

                Circle()
                    .fill(
                        RadialGradient(
                            colors: consoleSkin == .tweed ? [
                                .white, Color(red: 0.75, green: 0.75, blue: 0.75), Color(red: 0.30, green: 0.30, blue: 0.30)
                            ] : [
                                .goldLight, .goldMid, .goldDark
                            ],
                            center: UnitPoint(x: 0.35, y: 0.3),
                            startRadius: plunger * 0.03,
                            endRadius: plunger * 0.55
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.40), Color.black.opacity(0.35)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .overlay(
                        Circle()
                            .fill(Color.white.opacity(0.22))
                            .frame(width: plunger * 0.23, height: plunger * 0.16)
                            .offset(x: -plunger * 0.16, y: -plunger * 0.14)
                            .blur(radius: 0.3)
                    )
                    .frame(width: plunger, height: plunger)

                ForEach(0..<4, id: \.self) { index in
                    let angle = Angle.degrees(Double(index) * 90 + 45)
                    ScrewHeadView(size: screwSize, consoleSkin: consoleSkin)
                        .offset(
                            x: cos(angle.radians) * screwOrbit,
                            y: sin(angle.radians) * screwOrbit
                        )
                }
            }

            Text(label.uppercased())
                .font(.system(size: max(diameter * 0.16, 10), weight: .semibold))
                .fontWidth(.condensed)
                .kerning(0.9)
                .foregroundColor(.white)
        }
    }

    private var ringShadowColor: Color {
        switch state {
        case .neutral: return Color(red: 1.0, green: 0.62, blue: 0.05)
        case .orange: return Color(red: 1.0, green: 0.52, blue: 0.02)
        case .green: return Color(red: 0.2, green: 0.9, blue: 0.3)
        case .red: return Color(red: 1.0, green: 0.2, blue: 0.1)
        }
    }

    private var ringMetalStops: [Color] {
        if consoleSkin == .tweed {
            return [
                Color(red: 1.0, green: 1.0, blue: 1.0),
                Color(red: 0.95, green: 0.95, blue: 0.95),
                Color(red: 0.55, green: 0.55, blue: 0.55),
                Color(red: 0.20, green: 0.20, blue: 0.20),
                Color(red: 0.65, green: 0.65, blue: 0.65),
                Color(red: 1.0, green: 1.0, blue: 1.0)
            ]
        } else {
            return [
                Color(red: 0.98, green: 0.9, blue: 0.66),
                Color(red: 0.90, green: 0.74, blue: 0.40),
                Color(red: 0.73, green: 0.55, blue: 0.26),
                Color(red: 0.94, green: 0.82, blue: 0.53),
                Color(red: 0.98, green: 0.9, blue: 0.66)
            ]
        }
    }
}

// MARK: - Shared Menu Components

struct GoldPickerRow<T: Hashable>: View {
    let label: String
    let options: [(label: String, value: T)]
    @Binding var selection: T
    var disabled: Bool = false

    private let gold = Color.goldBorderMid

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(disabled ? .white.opacity(0.3) : .white.opacity(0.7))
            HStack(spacing: 8) {
                ForEach(options, id: \.value) { option in
                    let isSelected = selection == option.value
                    Button(action: {
                        guard !disabled else { return }
                        selection = option.value
                    }) {
                        Text(option.label)
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(isSelected ? .black : (disabled ? .white.opacity(0.3) : .white))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(isSelected ? gold : Color.black.opacity(0.6))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(isSelected ? gold : gold.opacity(disabled ? 0.2 : 0.45), lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(disabled)
                    .accessibilityLabel(option.label)
                    .accessibilityHint(isSelected ? "Currently selected" : "Select \(option.label)")
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct MenuSection<Content: View>: View {
    let title: String
    let gold: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .foregroundColor(gold)
                .tracking(2)
                .padding(.horizontal, 20)
                .padding(.top, 20)

            Divider()
                .background(gold.opacity(0.35))
                .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 14) {
                content()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
    }
}
