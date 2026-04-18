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
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.88, green: 0.88, blue: 0.84),
                                    Color(red: 0.62, green: 0.62, blue: 0.58),
                                    Color(red: 0.42, green: 0.42, blue: 0.38)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: index < 3 ? 2.8 - CGFloat(index) * 0.35 : 1.4)
                        .frame(height: clippedHeight)
                        .position(x: grooveCenters[index], y: clippedTopY + clippedHeight / 2)
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

    init(text: String, width: CGFloat, height: CGFloat, fontScale: CGFloat, isDarkScreen: Bool = false, glowTint: Color? = nil, hitTestingEnabled: Bool = false) {
        self.text = text
        self.width = width
        self.height = height
        self.fontScale = fontScale
        self.isDarkScreen = isDarkScreen
        self.glowTint = glowTint
        self.hitTestingEnabled = hitTestingEnabled
    }

    var body: some View {
        let bezelWidth = width + 24
        let bezelHeight = height + 18

        return ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.08, green: 0.08, blue: 0.1), Color(red: 0.18, green: 0.18, blue: 0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.6), radius: 8, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )

            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.black.opacity(0.65), lineWidth: 3)
                .padding(3)

            Group {
                if isDarkScreen {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.black.opacity(0.95), Color(red: 0.07, green: 0.07, blue: 0.08), Color.black.opacity(0.95)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .padding(8)
                } else {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            RadialGradient(
                                gradient: Gradient(stops: [
                                    .init(color: Color(white: 1.0, opacity: 0.85), location: 0.0),
                                    .init(color: Color(red: 1.0, green: 0.96, blue: 0.70), location: 0.08),
                                    .init(color: Color(red: 1.0, green: 0.78, blue: 0.12), location: 0.28),
                                    .init(color: Color(red: 1.0, green: 0.56, blue: 0.00), location: 0.40),
                                    .init(color: Color(red: 0.28, green: 0.12, blue: 0.00), location: 1.0)
                                ]),
                                center: .center,
                                startRadius: 2,
                                endRadius: 130
                            )
                        )
                        .padding(8)
                }
            }


            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.clear)
                .padding(12)

            Text(text.prefix(1).uppercased() + text.dropFirst())
                .font(.system(size: max(height * 0.78 * fontScale, 14), weight: .black, design: .default))
                .fontWidth(.condensed)
                .kerning(0.9)
                .allowsTightening(true)
                .foregroundColor(isDarkScreen ? .white : .black)
                .minimumScaleFactor(0.45)
                .padding(.horizontal, 12)
        }
        .frame(width: bezelWidth, height: bezelHeight)
        .overlay {
            if let glowTint {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(glowTint.opacity(0.78), lineWidth: 1.2)
                    .padding(3)
                    .shadow(color: glowTint.opacity(0.42), radius: 10)
            }
        }
        .allowsHitTesting(hitTestingEnabled)
    }
}

// MARK: - Screw Head View

struct ScrewHeadView: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.72, green: 0.63, blue: 0.44),
                            Color(red: 0.38, green: 0.31, blue: 0.18)
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

    private var glowStops: [Gradient.Stop] {
        switch state {
        case .neutral:
            return [
                .init(color: Color(white: 1.0, opacity: 1.0), location: 0.0),
                .init(color: Color(white: 1.0, opacity: 1.0), location: 0.12),
                .init(color: Color(red: 1.0, green: 0.96, blue: 0.70), location: 0.34),
                .init(color: Color(red: 1.0, green: 0.78, blue: 0.12), location: 0.54),
                .init(color: Color(red: 0.28, green: 0.12, blue: 0.00), location: 1.0)
            ]
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
                            colors: [
                                Color(red: 0.98, green: 0.9, blue: 0.66),
                                Color(red: 0.90, green: 0.74, blue: 0.40),
                                Color(red: 0.73, green: 0.55, blue: 0.26),
                                Color(red: 0.94, green: 0.82, blue: 0.53)
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
                            colors: [
                                Color(red: 0.98, green: 0.9, blue: 0.66),
                                Color(red: 0.90, green: 0.74, blue: 0.40),
                                Color(red: 0.73, green: 0.55, blue: 0.26)
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
                    ScrewHeadView(size: screwSize)
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
        [
            Color(red: 0.98, green: 0.9, blue: 0.66),
            Color(red: 0.90, green: 0.74, blue: 0.40),
            Color(red: 0.73, green: 0.55, blue: 0.26),
            Color(red: 0.94, green: 0.82, blue: 0.53),
            Color(red: 0.98, green: 0.9, blue: 0.66)
        ]
    }
}
