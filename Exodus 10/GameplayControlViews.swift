import SwiftUI

// MARK: - Gameplay Control Plate Shell

struct GameplayControlPlateShell: View {
    let isMenuExpanded: Bool
    let isStartupInputLockActive: Bool
    let isAutoplayActive: Bool
    let onAutoplay: () -> Void
    let onFretboard: () -> Void
    let onToggleMenu: () -> Void
    let onSelectMenuOption: (GameplayMenuOption) -> Void
    var consoleSkin: ConsoleSkin = .classic

    private let menuOptions: [GameplayMenuOption] = [.home, .audio, .guide, .learn]

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.chromeLight, Color(red: 0.58, green: 0.58, blue: 0.58)],
                                center: UnitPoint(x: 0.35, y: 0.3),
                                startRadius: 1,
                                endRadius: 16
                            )
                        )
                        .frame(width: UIConstants.powerIndicatorDiameter, height: UIConstants.powerIndicatorDiameter)
                        .overlay(Circle().stroke(Color.black.opacity(0.35), lineWidth: 1.2))
                    Circle()
                        .fill(Color.black.opacity(0.9))
                        .frame(width: UIConstants.powerIndicatorDotDiameter, height: UIConstants.powerIndicatorDotDiameter)
                }

                HStack(spacing: 8) {
                    plateButton(title: "AUTOPLAY", action: onAutoplay, isActive: isAutoplayActive)
                        .disabled(isStartupInputLockActive)
                        .accessibilityLabel(A11y.ControlPlate.autoplay)
                        .accessibilityHint(isAutoplayActive ? A11y.ControlPlate.autoplayHintOn : A11y.ControlPlate.autoplayHintOff)
                        .accessibilityAddTraits(isAutoplayActive ? [.isSelected] : [])
                    plateButton(title: "FRETBOARD", action: onFretboard)
                        .disabled(isStartupInputLockActive)
                        .accessibilityLabel(A11y.ControlPlate.fretboard)
                        .accessibilityHint(A11y.ControlPlate.fretboardHint)
                    plateButton(title: isMenuExpanded ? "CLOSE" : "MENU", action: onToggleMenu)
                        .accessibilityLabel(isMenuExpanded ? A11y.ControlPlate.menuClose : A11y.ControlPlate.menuOpen)
                        .accessibilityHint(isMenuExpanded ? A11y.ControlPlate.menuCloseHint : A11y.ControlPlate.menuOpenHint)
                }
            }

            if isMenuExpanded {
                HStack(spacing: 8) {
                    ForEach(menuOptions) { option in
                        plateButton(title: option.title) {
                            onSelectMenuOption(option)
                        }
                        .disabled(isStartupInputLockActive)
                        .accessibilityLabel(A11y.ControlPlate.menuOption(option.title))
                        .accessibilityHint(A11y.ControlPlate.menuOptionHint(option.title))
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, UIConstants.controlPlatePaddingH)
        .padding(.vertical, UIConstants.controlPlatePaddingV)
        .background(
            RoundedRectangle(cornerRadius: UIConstants.controlPlateRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: consoleSkin == .tweed ? [
                            .white, .chromeLight, .chromeBase, .chromeShadow, Color(red: 0.65, green: 0.65, blue: 0.65)
                        ] : [
                            .goldLight, .goldMid, .goldDark, .goldMidtone
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: UIConstants.controlPlateRadius, style: .continuous)
                        .stroke(Color.black.opacity(0.26), lineWidth: 1.2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: UIConstants.controlPlateRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.5), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.45), radius: 10, x: 0, y: 6)
        )
    }

    private func plateButton(title: String, action: @escaping () -> Void, isActive: Bool = false) -> some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: UIConstants.controlPlateButtonRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: consoleSkin == .tweed ? [
                                .white, Color(red: 0.90, green: 0.90, blue: 0.90), .chromeDark, .chromeMid
                            ] : [
                                .goldLight, .goldMid, .goldDark, .goldMidtone
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                if isActive {
                    RoundedRectangle(cornerRadius: UIConstants.controlPlateButtonRadius, style: .continuous)
                        .fill(Color.green.opacity(0.9))
                }
            }
            .frame(maxWidth: .infinity, minHeight: UIConstants.controlPlateButtonHeight, maxHeight: UIConstants.controlPlateButtonHeight)
            .overlay(
                RoundedRectangle(cornerRadius: UIConstants.controlPlateButtonRadius, style: .continuous)
                    .stroke(Color.black.opacity(0.34), lineWidth: 1.0)
            )
            .overlay(
                Text(title)
                    .font(.system(size: 10.35, weight: .regular, design: .monospaced))
                    .fontWidth(.compressed)
                    .kerning(0.8)
                    .foregroundStyle(Color.black.opacity(0.92))
            )
        }
        .buttonStyle(.plain)
    }
}

