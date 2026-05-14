import SwiftUI
import Combine
import AVFoundation

// MARK: - MaestroStartupSequenceView
// Animated "armed" text shown during the startup sequence.

struct MaestroStartupSequenceView: View {
    enum Phase {
        case armed
    }

    let elapsed: TimeInterval

    var body: some View {
        let state = MaestroStartupSequenceView.state(for: elapsed)
        let fontSize: CGFloat = UIMetrics.startupFontSize
        let fontWeight: Font.Weight = .black

        Text(state.text)
            .font(.system(size: fontSize, weight: fontWeight, design: .monospaced))
            .foregroundStyle(state.color)
            .multilineTextAlignment(.center)
            .opacity(state.isVisible ? 1 : 0)
            .animation(.easeInOut(duration: AnimationDurations.beatFlash), value: state.isVisible)
    }

    static func state(for elapsed: TimeInterval) -> (text: String, color: Color, isVisible: Bool, phase: Phase) {
        let armedFlashPeriod: TimeInterval = AnimationDurations.armedFlashPeriod
        let isVisible = Int(elapsed / armedFlashPeriod).isMultiple(of: 2)
        return ("Memorization Sequence Armed", Color.green.opacity(0.98), isVisible, .armed)
    }
}

typealias MaestroStartupState = MaestroStartupSequenceView.Phase

// MARK: - RowOneIdentifierOverlay
// Pair of mini-TV banners shown above the answer row.

struct RowOneIdentifierOverlay: View {
    let leftLabel: String
    let rightLabel: String
    let size: CGSize
    let rowHeight: CGFloat
    var consoleSkin: ConsoleSkin = .classic

    var body: some View {
        let bannerFont = UIFont.systemFont(ofSize: 18, weight: .semibold)
        let measuredWidth = max(
            textWidth(for: leftLabel, font: bannerFont),
            textWidth(for: rightLabel, font: bannerFont),
            textWidth(for: "Open Strings", font: bannerFont)
        )
        let bannerWidth = measuredWidth + 32
        let bannerHeight = max(min(rowHeight * UIMetrics.bannerHeightFraction, UIMetrics.bannerMaxHeight), UIMetrics.bannerMinHeight)

        return HStack(spacing: 16) {
            MiniTVFrame(text: leftLabel, width: bannerWidth, height: bannerHeight, fontScale: UIMetrics.bannerFontScale, consoleSkin: consoleSkin)
            MiniTVFrame(text: rightLabel, width: bannerWidth, height: bannerHeight, fontScale: UIMetrics.bannerFontScale, consoleSkin: consoleSkin)
        }
        .frame(width: size.width, height: rowHeight)
        .position(x: size.width / 2, y: rowHeight / 2)
        .allowsHitTesting(false)
    }

    private func textWidth(for text: String, font: UIFont) -> CGFloat {
        let attributes = [NSAttributedString.Key.font: font]
        return ceil(text.size(withAttributes: attributes).width)
    }
}

// MARK: - MaestroGameplayView UI helpers

extension MaestroGameplayView {

    @ViewBuilder func transportButtonBackground(fill: Color) -> some View {
        RoundedRectangle(cornerRadius: UIConstants.controlPlateButtonRadius, style: .continuous)
            .fill(fill)
            .overlay(
                RoundedRectangle(cornerRadius: UIConstants.controlPlateButtonRadius, style: .continuous)
                    .stroke(Color.black.opacity(0.34), lineWidth: 1.0)
            )
    }

    @ViewBuilder
    func maestroTransportButtonOverlay(
        proxyWidth: CGFloat,
        proxyHeight: CGFloat,
        lowerWhitePipingY: CGFloat,
        startButtonBlinkOn: Bool
    ) -> some View {
        let maestroTransportCenterY: CGFloat = lowerWhitePipingY + (proxyHeight - lowerWhitePipingY) * 0.28 + 17
        HStack(spacing: 6) {
            Button("START") { handleMaestroStartButton() }
                .frame(minWidth: 58, minHeight: 34, maxHeight: 34)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(startButtonBlinkOn ? Color.green.opacity(0.9) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .stroke(Color.black.opacity(0.34), lineWidth: 1.0)
                        )
                )
                .accessibilityLabel(A11y.Transport.start)
                .accessibilityHint(A11y.Transport.startHint)
            Button(isRoundPaused ? "RESUME" : "PAUSE") {
                if isRoundPaused { handleMaestroStartButton() }
                else { handleMaestroStopButton() }
            }
                .frame(minWidth: 58, minHeight: 34, maxHeight: 34)
                .disabled(isCodeScreensaverMode && !isRoundPaused)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(isRoundPaused ? Color.orange.opacity(0.85) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .stroke(Color.black.opacity(0.34), lineWidth: 1.0)
                        )
                )
                .accessibilityLabel(isRoundPaused ? A11y.Transport.resume : A11y.Transport.pause)
                .accessibilityHint(isRoundPaused ? A11y.Transport.resumeHint : A11y.Transport.pauseHint)
            Button("RESET") { handleMaestroResetButton() }
                .frame(minWidth: 58, minHeight: 34, maxHeight: 34)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(resetButtonPressed ? Color.green.opacity(0.8) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .stroke(Color.black.opacity(0.34), lineWidth: 1.0)
                        )
                )
                .accessibilityLabel(A11y.Transport.reset)
                .accessibilityHint(A11y.Transport.resetHint)
        }
        .font(.system(size: 12, weight: .bold, design: .monospaced))
        .foregroundStyle(Color.black.opacity(0.92))
        .buttonStyle(.plain)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: consoleSkin == .tweed ? [
                            .white, Color(red: 0.90, green: 0.90, blue: 0.90), .chromeDark, Color(red: 0.65, green: 0.65, blue: 0.65)
                        ] : [
                            .goldLight, .goldMid, .goldDark, .goldMidtone
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.black.opacity(0.26), lineWidth: 1.2)
                )
        )
        .frame(width: min((proxyWidth - 24) * 0.88, 370) * 0.72, height: 50)
        .position(x: proxyWidth / 2, y: maestroTransportCenterY)
        .opacity(codenameNemoEnabled ? 0 : 1)
    }

    func fretIndicatorOverlay(leftX: CGFloat, rightX: CGFloat, centerY: CGFloat, text: String, isHidden: Bool) -> some View {
        Group {
            if !isHidden {
                Text(text)
                    .font(.system(size: 24, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.96))
                    .shadow(color: Color.black.opacity(0.72), radius: 3, x: 0, y: 1)
                    .position(x: leftX, y: centerY)

                Text(text)
                    .font(.system(size: 24, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.96))
                    .shadow(color: Color.black.opacity(0.72), radius: 3, x: 0, y: 1)
                    .position(x: rightX, y: centerY)
            }
        }
        .allowsHitTesting(false)
    }

    func debugGridOverlay(size: CGSize, columns: Int, rows: Int) -> some View {
        let cellWidth = size.width / CGFloat(columns)
        let cellHeight = size.height / CGFloat(rows)

        return ZStack {
            Path { path in
                for column in 0...columns {
                    let x = CGFloat(column) * cellWidth
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                }

                for row in 0...rows {
                    let y = CGFloat(row) * cellHeight
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
            }
            .stroke(Color.red.opacity(0.45), lineWidth: 1)

            ForEach(0..<rows, id: \.self) { row in
                ForEach(0..<columns, id: \.self) { column in
                    let index = row * columns + column + 1
                    Text("\(index)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.red.opacity(0.85))
                        .position(
                            x: CGFloat(column) * cellWidth + cellWidth / 2,
                            y: CGFloat(row) * cellHeight + cellHeight / 2
                        )
                }
            }
        }
    }
}
