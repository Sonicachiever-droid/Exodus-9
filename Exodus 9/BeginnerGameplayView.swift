import SwiftUI
import Combine
import AVFoundation

// MARK: - Types and components from extracted files
// Types.swift contains: GameplayMenuOption, RefretMode, GameplayModeVariant, AnswerSide, LayoutMode, BeginnerCoursePhase, BeginnerRoundZeroIntroDisplayPhase, HighlightWindowShape, FretMath, GuitarStringLayout, baselineNutTargetY, resolvedNeckTopY
// ViewComponents.swift contains: StringLineOverlay, MiniTVFrame, ThumbButtonView

private struct WhiteNoteBoxOverlay: View {
    let centerY: CGFloat
    let availableSize: CGSize
    let boxHeight: CGFloat
    let neckWidth: CGFloat
    let activeStringNumbers: [Int]
    let answerFeedback: ThumbGlowState?
    let blinkingActive: Bool
    let blinkOrange: Bool
    let revealedNoteText: String?
    let revealedNoteTextByString: [Int: String]?
    let revealedNoteTextColor: Color

    var body: some View {
        let totalStrings = GuitarStringLayout.totalStrings
        let stratNutWidthInches: CGFloat = 1.650
        let stratStringSpanInches: CGFloat = 1.362
        let clampedBoxHeight = min(boxHeight, availableSize.height)
        let nutWidth = neckWidth * 0.99
        let overallWidth = availableSize.width
        let overallPadding = (overallWidth - nutWidth) / 2
        let widthPerInch = nutWidth / stratNutWidthInches
        let interStringSpacing = (stratStringSpanInches / CGFloat(totalStrings - 1)) * widthPerInch
        let edgeMargin = ((stratNutWidthInches - stratStringSpanInches) / 2) * widthPerInch
        let grooveCenters = (0..<totalStrings).map { index in
            overallPadding + edgeMargin + CGFloat(index) * interStringSpacing
        }
        let minCenterSpacing = grooveCenters.enumerated().dropFirst().map { idx, center in
            center - grooveCenters[idx - 1]
        }.min() ?? interStringSpacing
        let spacingGap = max(minCenterSpacing * 0.12, 6)
        let maxBoxWidthFromSpacing = max(minCenterSpacing - spacingGap, 0)
        let boxWidth = min(clampedBoxHeight * 1.8, maxBoxWidthFromSpacing)
        let activeSet = Set(activeStringNumbers)
        return ZStack {
            // Six individual translucent backgrounds for each answer box
            ForEach(0..<totalStrings, id: \.self) { index in
                let stringNumber = totalStrings - index
                let isActive = activeSet.contains(stringNumber)
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.black.opacity(0.42))
                    .frame(width: boxWidth, height: clampedBoxHeight)
                    .opacity(isActive ? 1 : 0.0001)
                    .position(x: grooveCenters[index], y: centerY)
            }

            ForEach(0..<totalStrings, id: \.self) { index in
                let stringNumber = totalStrings - index
                let isActive = activeSet.contains(stringNumber)
                let displayedNoteText = revealedNoteTextByString?[stringNumber] ?? revealedNoteText
                let noteIsAccidental = (displayedNoteText?.contains("#") == true) || (displayedNoteText?.contains("b") == true)
                let shouldUseAccidentalStyle = noteIsAccidental
                let fillColor: Color = {
                    guard isActive else { return Color.clear }
                    switch answerFeedback {
                    case .green:
                        return Color(red: 0.64, green: 0.98, blue: 0.70).opacity(0.95)
                    case .red:
                        return Color(red: 1.0, green: 0.62, blue: 0.58).opacity(0.95)
                    default:
                        if blinkingActive {
                            return blinkOrange ? Color(red: 1.0, green: 0.56, blue: 0.00).opacity(0.95) : Color.white.opacity(0.95)
                        }
                        return shouldUseAccidentalStyle ? Color.black.opacity(0.95) : Color.white.opacity(0.92)
                    }
                }()
                let strokeColor: Color = {
                    guard isActive else { return .clear }
                    switch answerFeedback {
                    case .green:
                        return Color(red: 0.04, green: 0.42, blue: 0.12).opacity(0.9)
                    case .red:
                        return Color(red: 0.48, green: 0.06, blue: 0.06).opacity(0.9)
                    default:
                        if blinkingActive {
                            return Color.black.opacity(0.8)
                        }
                        return shouldUseAccidentalStyle ? Color.white.opacity(0.86) : Color.black.opacity(0.72)
                    }
                }()

                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(fillColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(strokeColor, lineWidth: 2)
                    )
                    .frame(width: boxWidth, height: clampedBoxHeight)
                    .overlay {
                        if isActive, let displayedNoteText, !displayedNoteText.isEmpty {
                            Text(displayedNoteText)
                                .font(.system(size: min(clampedBoxHeight * 0.78, 28), weight: .black, design: .monospaced))
                                .minimumScaleFactor(0.32)
                                .lineLimit(1)
                                .foregroundStyle(shouldUseAccidentalStyle ? Color.white.opacity(0.96) : revealedNoteTextColor)
                                .padding(.horizontal, 1)
                        }
                    }
                    .opacity(isActive ? 1 : 0.0001)
                    .position(x: grooveCenters[index], y: centerY)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: activeStringNumbers)
        .animation(.easeInOut(duration: 0.18), value: answerFeedback)
    }
}

private struct GoldHorizontalPipingLine: View {
    let width: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 1.3, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.98, green: 0.9, blue: 0.66),
                            Color(red: 0.90, green: 0.74, blue: 0.40),
                            Color(red: 0.73, green: 0.55, blue: 0.26),
                            Color(red: 0.94, green: 0.82, blue: 0.53)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: width, height: 2.8)

            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 0.25, style: .continuous)
                    .fill(Color.black.opacity(0.72))
                    .frame(width: width, height: 0.45)

                Spacer(minLength: 0)

                RoundedRectangle(cornerRadius: 0.25, style: .continuous)
                    .fill(Color.black.opacity(0.72))
                    .frame(width: width, height: 0.45)
            }
            .frame(width: width, height: 2.8)

            RoundedRectangle(cornerRadius: 0.4, style: .continuous)
                .fill(Color.black.opacity(0.58))
                .frame(width: max(width - 2, 0), height: 0.7)
        }
    }

}

private final class GameplayAudioEngine {
    private let synthesizer = AVSpeechSynthesizer()
    private let defaultVoice = AVSpeechSynthesisVoice(language: "en-US")
    private let startupVoice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Fred-compact")

    func playBeat(volume: Double) {
        speak(
            "tick",
            volume: max(0.0, min(volume, 1.0)),
            rate: 0.44,
            pitch: 1.15,
            voice: defaultVoice
        )
    }

    func playNotePrompt(_ note: String, volume: Double) {
        let spoken = note
            .replacingOccurrences(of: "#", with: " sharp ")
            .replacingOccurrences(of: "b", with: " flat ")
            .replacingOccurrences(of: "+", with: " and ")
        speak(
            spoken,
            volume: max(0.0, min(volume, 1.0)),
            rate: 0.46,
            pitch: 0.95,
            voice: defaultVoice
        )
    }

    func speakPhrase(_ phrase: String, volume: Double, rate: Float = 0.45, pitch: Float = 1.05) {
        speak(
            phrase,
            volume: max(0.0, min(volume, 1.0)),
            rate: rate,
            pitch: pitch,
            voice: defaultVoice
        )
    }

    func speakStartupAlert(_ phrase: String, volume: Double) {
        speak(
            phrase,
            volume: max(0.0, min(volume, 1.0)),
            rate: 0.38,
            pitch: 0.35,
            voice: startupVoice ?? defaultVoice
        )
    }

    private func speak(
        _ text: String,
        volume: Double,
        rate: Float,
        pitch: Float,
        voice: AVSpeechSynthesisVoice?
    ) {
        guard !text.isEmpty else { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice ?? defaultVoice
        utterance.volume = Float(volume)
        utterance.rate = rate
        utterance.pitchMultiplier = pitch
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.speak(utterance)
    }
}

private struct GameplayControlPlateShell: View {
    let isMenuExpanded: Bool
    let isStartupInputLockActive: Bool
    let isAutoplayActive: Bool
    let onAutoplay: () -> Void
    let onFretboard: () -> Void
    let onToggleMenu: () -> Void
    let onSelectMenuOption: (GameplayMenuOption) -> Void

    private let menuOptions: [GameplayMenuOption] = [.home, .learn, .phases, .audio]

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(red: 0.95, green: 0.95, blue: 0.95), Color(red: 0.58, green: 0.58, blue: 0.58)],
                                center: UnitPoint(x: 0.35, y: 0.3),
                                startRadius: 1,
                                endRadius: 16
                            )
                        )
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(Color.black.opacity(0.35), lineWidth: 1.2))
                    Circle()
                        .fill(Color.black.opacity(0.9))
                        .frame(width: 14, height: 14)
                }

                HStack(spacing: 8) {
                    plateButton(title: "AUTOPLAY", action: onAutoplay, isActive: isAutoplayActive)
                        .disabled(isStartupInputLockActive)
                    plateButton(title: "FRETBOARD", action: onFretboard)
                        .disabled(isStartupInputLockActive)
                    plateButton(title: isMenuExpanded ? "CLOSE" : "MENU", action: onToggleMenu)
                }
            }

            if isMenuExpanded {
                HStack(spacing: 8) {
                    ForEach(menuOptions) { option in
                        plateButton(title: option.title) {
                            onSelectMenuOption(option)
                        }
                        .disabled(isStartupInputLockActive)
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.98, green: 0.9, blue: 0.66),
                            Color(red: 0.9, green: 0.74, blue: 0.4),
                            Color(red: 0.73, green: 0.55, blue: 0.26),
                            Color(red: 0.94, green: 0.82, blue: 0.53)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.black.opacity(0.26), lineWidth: 1.2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
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
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.90, green: 0.76, blue: 0.44),
                                Color(red: 0.72, green: 0.54, blue: 0.26),
                                Color(red: 0.87, green: 0.72, blue: 0.40)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                if isActive {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color.green.opacity(0.9))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 34, maxHeight: 34)
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
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

private struct StartupSequenceView: View {
    enum Phase {
        case systemOnline
        case phaseOne
        case armed
    }

    let elapsed: TimeInterval
    let showFullSequence: Bool
    let armedText: String

    init(elapsed: TimeInterval, showFullSequence: Bool = true, armedText: String = "Memorization Sequence Armed") {
        self.elapsed = elapsed
        self.showFullSequence = showFullSequence
        self.armedText = armedText
    }

    var body: some View {
        let state = Self.state(for: elapsed, showFullSequence: showFullSequence, armedText: armedText)
        let fontSize: CGFloat = state.phase == .armed ? 29.6 : 34
        let fontWeight: Font.Weight = .black

        Text(state.text)
            .font(.system(size: fontSize, weight: fontWeight, design: .monospaced))
            .foregroundStyle(state.color)
            .minimumScaleFactor(0.3)
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .shadow(color: state.color.opacity(0.95), radius: 14, x: 0, y: 0)
            .shadow(color: state.color.opacity(0.6), radius: 26, x: 0, y: 0)
            .opacity(state.isVisible ? 1 : 0)
    }

    static func state(for elapsed: TimeInterval, showFullSequence: Bool = true, armedText: String = "Memorization Sequence Armed") -> (text: String, color: Color, isVisible: Bool, phase: Phase) {
        let firstFlashPeriod: TimeInterval = 1.0
        let secondFlashPeriod: TimeInterval = 1.0
        let armedFlashPeriod: TimeInterval = 1.0
        let firstBlockDuration = firstFlashPeriod * 4
        let secondBlockDuration = firstBlockDuration + (secondFlashPeriod * 4)

        if !showFullSequence {
            let isVisible = Int(elapsed / armedFlashPeriod).isMultiple(of: 2)
            return (armedText, Color.green.opacity(0.98), isVisible, .armed)
        }

        if elapsed < firstBlockDuration {
            let isVisible = Int(elapsed / firstFlashPeriod).isMultiple(of: 2)
            return ("SYSTEM ONLINE", Color.orange.opacity(0.98), isVisible, .systemOnline)
        }

        if elapsed < secondBlockDuration {
            let localElapsed = elapsed - firstBlockDuration
            let isVisible = Int(localElapsed / secondFlashPeriod).isMultiple(of: 2)
            return ("PHASE 1", Color.red.opacity(0.98), isVisible, .phaseOne)
        }

        let localElapsed = elapsed - secondBlockDuration
        let isVisible = Int(localElapsed / armedFlashPeriod).isMultiple(of: 2)
        return (armedText, Color.green.opacity(0.98), isVisible, .armed)
    }
}

private struct FullScreenElephantBackground: View {
    var body: some View {
        GeometryReader { geo in
            let bleed: CGFloat = 48

            Image("MARSHALL ELEPHANT")
                .resizable(resizingMode: .tile)
                .frame(width: geo.size.width + bleed * 2, height: geo.size.height + bleed * 2)
                .scaleEffect(x: 1.15, y: 1.15, anchor: .center)
                .brightness(0.08)
                .saturation(1.05)
                .overlay(Color.black.opacity(0.18))
                .offset(x: -bleed, y: -bleed)
        }
    }
}

private func logNutBaselineDelta(_ delta: CGFloat) {
    if abs(delta) > 0.5 {
        print("[Project Genesis] Nut baseline delta: \(delta)")
    }
}

private func logAlignmentDelta(_ delta: CGFloat) {
    if abs(delta) > 0.5 {
        print("[Project Genesis] Midpoint/bisector delta: \(delta)")
    }
}

private func logAlignmentDiagnostics(
    neckTopY: CGFloat,
    activeMidpoint: CGFloat,
    highlightCenterY: CGFloat,
    highlightTopGridLineY: CGFloat,
    gridRowHeight: CGFloat
) {
    let blueMidpointY = neckTopY + activeMidpoint
    let greenBisectorY = highlightCenterY
    let nutBottomRowY = highlightTopGridLineY + 2 * gridRowHeight
    logAlignmentDelta(blueMidpointY - greenBisectorY)
    logNutBaselineDelta(neckTopY - nutBottomRowY)
}

private struct MarshallElephantOverlay: View {
    let canvasSize: CGSize
    let highlightWidth: CGFloat
    let highlightHeight: CGFloat
    let highlightCenter: CGPoint
    let highlightCornerRadius: CGFloat

    var body: some View {
        let bleed: CGFloat = 36

        Image("MARSHALL ELEPHANT")
            .resizable(resizingMode: .tile)
            .frame(width: canvasSize.width + (bleed * 2), height: canvasSize.height + (bleed * 2))
            .scaleEffect(x: 1.15, y: 1.15, anchor: .center)
            .brightness(0.12)
            .saturation(1.05)
            .overlay(Color.black.opacity(0.2))
            .offset(x: -bleed, y: -bleed)
        .frame(width: canvasSize.width, height: canvasSize.height)
        .clipped()
        .mask(maskShape)
        .frame(width: canvasSize.width, height: canvasSize.height)
    }

    private var maskShape: some View {
        Rectangle()
            .frame(width: canvasSize.width, height: canvasSize.height)
            .overlay {
                HighlightWindowShape(cornerRadius: highlightCornerRadius)
                    .frame(width: highlightWidth, height: highlightHeight)
                    .position(x: highlightCenter.x, y: highlightCenter.y)
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
    }
}

// NEW: This view locks the hole in the elephant tolex and the gold border together forever
private struct GreenBisectorLine: View {
    var body: some View {
        Rectangle()
            .fill(Color.green)
            .frame(height: 2)
    }
}

private struct ElephantWindowView: View {
    let canvasSize: CGSize
    let highlightWidth: CGFloat
    let highlightHeight: CGFloat
    let highlightCenter: CGPoint
    let highlightCornerRadius: CGFloat

    var body: some View {
        ZStack {
            // Elephant with the hole cut out
            MarshallElephantOverlay(
                canvasSize: canvasSize,
                highlightWidth: highlightWidth,
                highlightHeight: highlightHeight,
                highlightCenter: highlightCenter,
                highlightCornerRadius: highlightCornerRadius
            )
            
            // Gold border drawn in the exact same position as the hole
            HighlightWindowGoldBorder(
                width: highlightWidth,
                height: highlightHeight,
                cornerRadius: highlightCornerRadius
            )
            .position(x: highlightCenter.x, y: highlightCenter.y)
        }
    }
}

private struct HighlightWindowGoldBorder: View {
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        HighlightWindowShape(cornerRadius: cornerRadius)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.82, blue: 0.47),
                        Color(red: 0.78, green: 0.6, blue: 0.22),
                        Color(red: 0.97, green: 0.85, blue: 0.5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 4
            )
            .frame(width: width, height: height)
    }
}

private struct GoldPipingBorder: View {
    let bottomInset: CGFloat

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .inset(by: 1.75)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color(red: 0.95, green: 0.82, blue: 0.47),
                            Color(red: 0.78, green: 0.6, blue: 0.22),
                            Color(red: 0.97, green: 0.85, blue: 0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3.5
                )
                .shadow(color: Color.black.opacity(0.45), radius: 12, x: 0, y: 8)

            ContainerRelativeShape()
                .inset(by: 3.5)
                .stroke(Color.black.opacity(0.6), lineWidth: 1.5)
        }
        .padding(.bottom, bottomInset)
        .ignoresSafeArea()
    }
}

private struct DeveloperCodeRunnerView: View {
    @State private var startDate: Date = .now

    private struct RenderState {
        let renderedLines: [String]
        let lineHeight: CGFloat
        let offsetY: CGFloat
    }

    private static let sourceText: String = {
        if let url = Bundle.main.url(forResource: "ContentViewSource", withExtension: "txt"),
           let text = try? String(contentsOf: url, encoding: .utf8),
           !text.isEmpty {
            return text
        }
        if let text = try? String(contentsOfFile: #filePath, encoding: .utf8), !text.isEmpty {
            return text
        }
        return "import SwiftUI\nstruct ContentView: View {\n    var body: some View {\n        Text(\"Loading Source\")\n    }\n}"
    }()

    private static let lines: [String] = {
        let split = sourceText.components(separatedBy: .newlines)
        return split.isEmpty ? ["// source unavailable"] : split
    }()

    private static let charsPerSecond: Double = 42
    private static let postLineHold: Double = 0.12
    private static let lineHeight: CGFloat = 14
    private static let loopPause: Double = 0.9
    private static let lineDurations: [Double] = lines.map { max(Double($0.count) / charsPerSecond, 0.02) + postLineHold }
    private static let cumulativeDurations: [Double] = lineDurations.reduce(into: []) { partial, duration in
        partial.append((partial.last ?? 0) + duration)
    }
    private static let typingDuration: Double = lineDurations.reduce(0, +)
    private static let cycleDuration: Double = max(typingDuration + loopPause, 0.1)

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 0.03)) { context in
                let elapsed = context.date.timeIntervalSince(startDate)
                let state = makeRenderState(elapsed: elapsed, viewportHeight: geo.size.height)

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(state.renderedLines.enumerated()), id: \.offset) { index, line in
                        Text(line)
                            .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
                            .foregroundStyle(color(for: index))
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, minHeight: state.lineHeight, maxHeight: state.lineHeight, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .offset(y: state.offsetY)
                .clipped()
            }
        }
    }

    private func makeRenderState(elapsed: TimeInterval, viewportHeight: CGFloat) -> RenderState {
        let cycleElapsed = elapsed.truncatingRemainder(dividingBy: Self.cycleDuration)

        let activeLine: Int = {
            if cycleElapsed >= Self.typingDuration {
                return max(Self.lines.count - 1, 0)
            }
            return Self.cumulativeDurations.firstIndex(where: { cycleElapsed <= $0 }) ?? max(Self.lines.count - 1, 0)
        }()

        let elapsedIntoLine: Double = {
            if cycleElapsed >= Self.typingDuration {
                return Self.lineDurations.last ?? 0
            }
            let previousTotal = activeLine > 0 ? Self.cumulativeDurations[activeLine - 1] : 0
            return max(cycleElapsed - previousTotal, 0)
        }()

        let currentLineDuration = Self.lineDurations.isEmpty ? 1 : Self.lineDurations[activeLine]
        let typingWindow = max(currentLineDuration - Self.postLineHold, 0.02)
        let typedChars = min(
            Int(max(elapsedIntoLine, 0) * Self.charsPerSecond),
            Self.lines[activeLine].count
        )

        var renderedLines: [String] = []
        if activeLine > 0 {
            renderedLines.append(contentsOf: Self.lines.prefix(activeLine))
        }
        let activeText = String(Self.lines[activeLine].prefix(max(typedChars, 0)))
        let showCursor = cycleElapsed < Self.typingDuration && elapsedIntoLine <= typingWindow
        renderedLines.append(activeText + (showCursor ? "▋" : ""))

        let typedProgress = min(max((elapsedIntoLine / currentLineDuration), 0), 1)
        let contentOffset = (CGFloat(activeLine) + CGFloat(typedProgress)) * Self.lineHeight
        let baselineY = viewportHeight - Self.lineHeight

        return RenderState(
            renderedLines: renderedLines,
            lineHeight: Self.lineHeight,
            offsetY: baselineY - contentOffset
        )
    }

    private func color(for index: Int) -> Color {
        let palette: [Color] = [.orange, .cyan, .mint, .pink, .yellow, .green]
        return palette[index % palette.count].opacity(0.95)
    }
}

private struct DeveloperConsoleFrame: View {
    let width: CGFloat
    let height: CGFloat
    let isScreensaverMode: Bool
    let layoutMode: LayoutMode
    let roundTitle: String
    let fretTitle: String
    let stringTitle: String
    let bankText: String
    let highScoreText: String
    let scaleRepetitionText: String
    let promptText: String
    let startupElapsed: TimeInterval
    let showStartupSequence: Bool
    let startupShowFullSequence: Bool
    let startupArmedText: String
    let beginnerRoundStatusText: String?
    let phaseAnnouncementText: AttributedString?
    let phaseCompletedMessageText: AttributedString?
    let celebrationActive: Bool
    let celebrationFlashOn: Bool
    let centeredStatusMessage: String?
    let centeredStatusColor: Color
    let currentRound: Int
    let currentRoundInPhase: Int
    let repetitionCountColor: Color
    let walletColor: Color

    private var isHintVisible: Bool {
        promptText.lowercased().hasPrefix("hint:")
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    celebrationActive
                        ? LinearGradient(
                            colors: celebrationFlashOn
                                ? [Color(red: 0.95, green: 0.08, blue: 0.08), Color(red: 0.55, green: 0.0, blue: 0.0)]
                                : [Color(red: 0.25, green: 0.0, blue: 0.0), Color(red: 0.6, green: 0.02, blue: 0.02)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
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

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color(red: 0.95, green: 0.82, blue: 0.47),
                            Color(red: 0.78, green: 0.6, blue: 0.22),
                            Color(red: 0.97, green: 0.85, blue: 0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.5
                )
                .padding(1.5)

            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    celebrationActive
                        ? LinearGradient(
                            colors: celebrationFlashOn
                                ? [Color(red: 1.0, green: 0.14, blue: 0.14), Color(red: 0.82, green: 0.0, blue: 0.0), Color(red: 1.0, green: 0.14, blue: 0.14)]
                                : [Color(red: 0.42, green: 0.0, blue: 0.0), Color(red: 0.16, green: 0.0, blue: 0.0), Color(red: 0.42, green: 0.0, blue: 0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        : LinearGradient(
                            colors: [Color.black.opacity(0.96), Color(red: 0.07, green: 0.07, blue: 0.08), Color.black.opacity(0.96)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                )
                .padding(4)
            ZStack {
                if isScreensaverMode {
                            ZStack {
                                if !showStartupSequence {
                                    DeveloperCodeRunnerView()
                                        .padding(.horizontal, 12)
                                        .padding(.top, 4)
                                        .padding(.bottom, 10)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                }

                                if showStartupSequence {
                                    StartupSequenceView(
                                        elapsed: startupElapsed,
                                        showFullSequence: startupShowFullSequence,
                                        armedText: startupArmedText
                                    )
                                        .padding(.horizontal, 10)
                                        .padding(.top, 24)
                                        .padding(.bottom, 8)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                }
                            }
                        } else if celebrationActive {
                            Text("CONGRATULATIONS!")
                                .font(.system(size: min(width * 0.102, 31), weight: .black, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.98))
                                .minimumScaleFactor(0.62)
                                .multilineTextAlignment(.center)
                                .shadow(color: Color.black.opacity(0.45), radius: 3)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        } else if let msg = centeredStatusMessage {
                            Text(msg)
                                .font(.system(size: min(width * 0.086, 26), weight: .black, design: .monospaced))
                                .foregroundStyle(centeredStatusColor)
                                .minimumScaleFactor(0.7)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        } else {
                            ZStack {
                                if isHintVisible {
                                    Text(promptText.replacingOccurrences(of: "hint:", with: "", options: [.caseInsensitive], range: nil).trimmingCharacters(in: .whitespaces))
                                        .font(.system(size: hintFontSize(for: promptText) * 1.15, weight: .black, design: .monospaced))
                                        .foregroundStyle(Color(red: 0.2, green: 0.08, blue: 0.0).opacity(0.98))
                                        .multilineTextAlignment(.center)
                                        .lineLimit(nil)
                                        .minimumScaleFactor(0.5)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                } else {
                                    ZStack {
                                        // Grid overlay for positioning reference (beginner mode only)
                                        if layoutMode == .beginner {
                                            GridOverlay()
                                                .allowsHitTesting(false)
                                        }
                                        
                                        VStack(spacing: 0) {
                                            // Only show 3x/Round/Wallet line when phase announcement or completed message is not active
                                            if phaseAnnouncementText == nil && phaseCompletedMessageText == nil {
                                                HStack {
                                                    Text(scaleRepetitionText)
                                                        .font(.system(size: 20, weight: .black, design: .monospaced))
                                                        .foregroundStyle(repetitionCountColor)
                                                    Spacer()
                                                    Text("Round \(currentRoundInPhase)")
                                                        .font(.system(size: min(width * 0.095, 26), weight: .black, design: .monospaced))
                                                        .foregroundStyle(Color.white)
                                                    Spacer()
                                                    VStack(alignment: .trailing, spacing: 2) {
                                                        Text("WALLET")
                                                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                                                            .foregroundStyle(Color.white.opacity(0.9))
                                                        Text(bankText)
                                                            .font(.system(size: 16, weight: .black, design: .monospaced))
                                                            .foregroundStyle(Color.green.opacity(0.96))
                                                    }
                                                }
                                            }

                                            Spacer(minLength: 0)

                                            Spacer(minLength: 0)
                                        }
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                                        if let phaseAnnouncementText {
                                            Text(phaseAnnouncementText)
                                                .font(.system(size: min(width * 0.095, 26), weight: .black, design: .monospaced))
                                                .minimumScaleFactor(0.7)
                                                .lineLimit(4)
                                                .multilineTextAlignment(.center)
                                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 10)
                                                .allowsHitTesting(false)
                                        } else if let phaseCompletedMessageText {
                                            Text(phaseCompletedMessageText)
                                                .font(.system(size: min(width * 0.095, 26), weight: .black, design: .monospaced))
                                                .minimumScaleFactor(0.7)
                                                .lineLimit(2)
                                                .multilineTextAlignment(.center)
                                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 10)
                                                .allowsHitTesting(false)
                                        } else if let beginnerRoundStatusText {
                                            let statusLines = beginnerRoundStatusText.components(separatedBy: "\n")
                                            let titleLine: String = statusLines.count == 1 ? "" : (statusLines.indices.contains(1) ? statusLines[1] : "")
                                            let notesLine: String = statusLines.count == 1 ? statusLines[0] : (statusLines.indices.contains(2) ? statusLines[2] : "")
                                            let startupMappedBlock = [titleLine, notesLine]
                                                .filter { !$0.isEmpty }
                                                .joined(separator: "\n")

                                            if !startupMappedBlock.isEmpty {
                                                Text(startupMappedBlock)
                                                    .font(.system(size: min(width * 0.19, 52), weight: .black, design: .monospaced))
                                                    .foregroundStyle(Color.green.opacity(0.98))
                                                    .minimumScaleFactor(0.3)
                                                    .lineLimit(2)
                                                    .multilineTextAlignment(.center)
                                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                                    .padding(.horizontal, 10)
                                                    .padding(.top, 24)
                                                    .padding(.bottom, 8)
                                                    .allowsHitTesting(false)
                                            } else {
                                                EmptyView()
                                            }
                                        }
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                }
                            }
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal, 14)
                            .padding(.top, 10)
                            .padding(.bottom, 10)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
            }
        .scaleEffect(isHintVisible ? 1.02 : 1.0)
        .frame(width: width, height: height)
    }

    private func hintFontSize(for text: String) -> CGFloat {
        let clean = text.replacingOccurrences(of: "hint:", with: "", options: [.caseInsensitive], range: nil)
        let trimmed = clean.trimmingCharacters(in: .whitespaces)
        let base: CGFloat = 54
        let reduction = CGFloat(max(trimmed.count - 12, 0)) * 1.2
        return max(24, base - reduction)
    }

    private func adaptiveProgressFontSize(for progressLine: String) -> CGFloat {
        let compact = progressLine.replacingOccurrences(of: " ", with: "")
        let count = max(compact.count, 1)
        let base = min(width * 0.205, 54)
        let reduction = CGFloat(max(count - 4, 0)) * 2.9
        return max(26, base - reduction)
    }
}

private struct DeveloperTVStreakMeterView: View {
    let litColumns: Int
    let failureActive: Bool
    let failureVisibleColumns: Int

    private let totalColumns: Int = 20

    var body: some View {
        let activeColumns = min(max(litColumns, 0), totalColumns)
        let visibleFailureColumns = min(max(failureVisibleColumns, 0), totalColumns)

        VStack(spacing: 4) {
            ForEach(0..<2, id: \.self) { _ in
                HStack(spacing: 3) {
                    ForEach(0..<totalColumns, id: \.self) { index in
                        let isLit: Bool = {
                            if failureActive {
                                return index < visibleFailureColumns
                            }
                            return index < activeColumns
                        }()
                        let isTwentiethColumn = index == totalColumns - 1
                        let isWarningColumn = index >= 15
                        let fillColor: Color = {
                            guard isLit else { return Color(red: 0.12, green: 0.14, blue: 0.12).opacity(0.42) }
                            if failureActive {
                                return Color(red: 1.0, green: 0.22, blue: 0.18).opacity(0.96)
                            }
                            if isTwentiethColumn {
                                return Color(red: 0.35, green: 0.66, blue: 1.0).opacity(0.96)
                            }
                            if isWarningColumn {
                                return Color(red: 1.0, green: 0.82, blue: 0.16).opacity(0.96)
                            }
                            return Color(red: 0.58, green: 1.0, blue: 0.22).opacity(0.96)
                        }()
                        let strokeColor: Color = {
                            guard isLit else { return Color.white.opacity(0.08) }
                            if failureActive {
                                return Color(red: 0.7, green: 0.05, blue: 0.04).opacity(0.95)
                            }
                            if isTwentiethColumn {
                                return Color(red: 0.06, green: 0.22, blue: 0.62).opacity(0.94)
                            }
                            if isWarningColumn {
                                return Color(red: 0.72, green: 0.46, blue: 0.0).opacity(0.9)
                            }
                            return Color(red: 0.12, green: 0.4, blue: 0.05).opacity(0.92)
                        }()
                        let shadowColor: Color = {
                            guard isLit else { return .clear }
                            if failureActive {
                                return Color.red.opacity(0.75)
                            }
                            if isTwentiethColumn {
                                return Color.blue.opacity(0.75)
                            }
                            if isWarningColumn {
                                return Color.yellow.opacity(0.65)
                            }
                            return Color.green.opacity(0.75)
                        }()

                        RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                            .fill(fillColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                                    .stroke(strokeColor, lineWidth: 0.8)
                            )
                            .shadow(color: shadowColor, radius: isLit ? 3 : 0)
                    }
                }
            }
        }
    }
}

struct BeginnerGameplayView: View {
    let onMenuSelection: ((GameplayMenuOption) -> Void)?
    let selectedMode: RefretMode
    let selectedPhase: Int
    let beatBPM: Int
    let beatVolume: Double
    let stringVolume: Double
    @Binding var playStartingFret: Int
    @Binding var playRepetitions: Int
    @Binding var playDirectionRawValue: String
    @Binding var playEnableHighFrets: Bool
    @Binding var playLessonStyle: String
    @Binding var walletDollars: Int
    @Binding var balanceDollars: Int
    @AppStorage("numbers3.runtime.directionLockActive") private var directionLockActive: Bool = false

    @State private var audioSettings = AudioSettings()
    @State private var showAudioPage: Bool = false
    private let layoutMode: LayoutMode = .beginner

    @Environment(\.displayScale) private var displayScale
    private let totalFrets: Int = 20
    private var maxFretOffset: Int { totalFrets }
    private var minFretOffset: Int { -totalFrets }
    private var modeVariant: GameplayModeVariant {
        // For phases 1-8 in beginner mode, use effective lesson style
        if layoutMode == .beginner {
            switch effectiveLessonStyle {
            case "chord":
                return .chord
            case "random", "sequential":
                return .freestyle
            default:
                break
            }
        }

        switch selectedMode {
        case .beat:
            return .beat
        case .chord:
            return .chord
        case .mixed:
            switch currentRound % 3 {
            case 1:
                return .beat
            case 2:
                return .chord
            default:
                return .freestyle
            }
        case .freestyle, .oneHand, .twoHand:
            return .freestyle
        }
    }

    private var isPhaseDescending: Bool {
        [2, 4, 6, 8].contains(beginnerRuntime.currentPhaseNumber)
    }

    private var usesRandomStringOrder: Bool {
        [5, 6].contains(beginnerRuntime.currentPhaseNumber)
    }

    private var effectiveLessonStyle: String {
        switch beginnerRuntime.currentPhaseNumber {
        case 1...4:
            // Default to sequential for new players, but allow explicit chord or random override
            if playLessonStyle == "chord" || playLessonStyle == "random" {
                return playLessonStyle
            }
            return "sequential"
        case 5...6:
            return "chord"
        case 7...8:
            return "random"
        default:
            return playLessonStyle
        }
    }

    private var phaseLabel: String {
        "PHASE \(selectedPhase)"
    }

    private var showMaestroOverlays: Bool {
        layoutMode == .maestro
    }

    private var activeStringOrder: [Int] {
        let baseOrder: [Int] = {
            switch selectedMode {
            case .oneHand:
                return [1, 2, 3, 4]
            default:
                return [1, 2, 3, 4, 5, 6]
            }
        }()

        switch modeVariant {
        case .chord:
            return Array(baseOrder.enumerated().compactMap { index, value in
                index.isMultiple(of: 2) ? value : nil
            })
        case .freestyle, .beat:
            return baseOrder
        }
    }

    private var modePayoutMultiplier: Double {
        switch selectedMode {
        case .freestyle:
            return 1.0
        case .beat:
            return 1.25
        case .chord:
            return 1.4
        case .mixed:
            return 1.6
        case .oneHand, .twoHand:
            return 1.15
        }
    }
    private let chromaticSharps: [String] = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    private let chromaticFlats: [String] = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"]
    private let openNoteByString: [Int: String] = [
        6: "E",
        5: "A",
        4: "D",
        3: "G",
        2: "B",
        1: "E"
    ]
    private let phaseOneHintByString: [Int: String] = [
        1: "Old McDonald has a farm...?",
        2: "What note is a fourth below E?",
        3: "What note is a third below B?",
        4: "What note is a fourth below G?",
        5: "What note is a fourth below D?",
        6: "What note is a fourth below A?"
    ]
    private let codenameNemoEnabled: Bool = false
    private let scaleLengthInches: Double = 25.5
    private let debugGridRows: Int = 8
    private var maxWindowRow: Int { (debugGridRows - 1) * 2 } // half-step increments across rows
    @State private var currentFretStart: Int = 0
    @State private var currentWindowRow: Int = 2
    @State private var leftThumbState: ThumbGlowState = .neutral
    @State private var rightThumbState: ThumbGlowState = .neutral
    @State private var beginnerPressedButtonIndex: Int? = nil
    @State private var beginnerPressedButtonCorrect: Bool = false
    @State private var currentRound: Int = 0
    @State private var roundStringIndex: Int = 0
    @State private var isDescendingPhase: Bool = false
    @State private var leftChoiceNote: String = ""
    @State private var rightChoiceNote: String = ""
    
    // Chord system integration
    @StateObject private var chordGenerator = ChordGenerator()
    // Random style integration
    @StateObject private var randomNoteGenerator = RandomNoteGenerator()
    // Sequential style integration
    @StateObject private var sequentialNoteGenerator = SequentialNoteGenerator()
    @State private var correctAnswerSide: AnswerSide = .left
    @State private var isResolvingAnswer: Bool = false
    @State private var activePickedStringNumbers: [Int] = [1]
    @State private var activeAnswerFeedback: ThumbGlowState? = nil
    @State private var currentQuestionIsAccidental: Bool = false
    @State private var introWindowBlack: Bool = true
    @State private var introDidRun: Bool = false
    @State private var isCodeScreensaverMode: Bool = true
    @State private var bankDollars: Int = 0
    @State private var displayedBankDollars: Int = 0
    @State private var highScoreDollars: Int = 0
    @State private var startupSequenceStartDate: Date = .now
    @State private var startupSequenceElapsed: TimeInterval = 0
    @State private var startupSequenceActivated: Bool = false
    @State private var assetToNutBottomDelta: CGFloat? = nil
    @State private var questionBoxAssistActive: Bool = false
    @State private var gameplayMenuExpanded: Bool = false
    @State private var developerPromptText: String = ""
    @State private var currentCorrectNote: String = ""
    @State private var lastResolvedCorrectNote: String? = nil
    @State private var lastResolvedCorrectString: Int? = nil
    @State private var currentPromptStrings: [Int] = [1]
    @State private var beatQuestionDeadline: Date? = nil
    @State private var showFretboardGuide: Bool = false
    @State private var isRoundArmed: Bool = true
    @State private var isRoundPaused: Bool = false
    @State private var transportStoppedForResume: Bool = false
    @State private var roundRevealElapsedBeats: Double = 0
    @State private var roundRevealLastTickDate: Date? = nil
    @State private var isBackingTrackPlaying: Bool = false
    @State private var isLaunchTransitionAnimating: Bool = false
    @State private var launchTileScale: CGFloat = 1
    @State private var launchTileOpacity: Double = 1
    @State private var startupNeckVisualsHidden: Bool = false
    @State private var startupStartButtonBlinkOn: Bool = false
    @State private var startupStartButtonNextBlinkDate: Date? = nil
    @State private var beatPulseActive: Bool = false
    @State private var beatCountInRemaining: Int = 0
    @State private var nextBeatTickDate: Date? = nil
    @State private var questionBoxPulsePhase: Bool = false
    @State private var nextQuestionBoxPulseDate: Date? = nil
    @State private var questionBoxIntroProgress: CGFloat = 0
    @State private var streakMeterLitColumns: Int = 0
    @State private var streakMeterFailureActive: Bool = false
    @State private var streakMeterFailureVisibleColumns: Int = 0
    @State private var lastPromptedCorrectNote: String? = nil
    @State private var lastPromptedStringHalf: AnswerSide? = nil
    @State private var lastPromptedStringNumber: Int? = nil
    @State private var recentPromptedCorrectNotes: [String] = []
    @State private var beginnerRuntime = BeginnerRuntimeState()

    private enum StartupSpeechPhase {
        case idle
        case pendingSystem
        case pendingPhase
        case pendingArmed
    }

    private struct BeginnerStageTemplate {
        let root: String
        let titleSuffix: String
        let intervals: [Int]
        let bassSemitoneTarget: Int
        let endsCycle: Bool
    }

    private struct BeginnerScaleStage {
        let title: String
        let notes: [String]
        let bassSemitoneTarget: Int
        let endsCycle: Bool
    }

    private struct BeginnerRuntimeState {
        var autoPlayEnabled: Bool = false
        var autoPlayNextDate: Date? = nil
        var celebrationFlashOn: Bool = false
        var celebrationNextFlashDate: Date? = nil
        var beatLightFlashOn: Bool = false
        var beatLightLastProcessedBeat: Int? = nil
        var beatLightIntroMeasureSkipped: Bool = false
        var revealStartBeatBucket: Int? = nil
        var introStartBeatBucket: Int? = nil
        var showRoundZeroIntroSequence: Bool = false
        var roundOneIntroActive: Bool = false
        var roundOneSequenceStartDate: Date? = nil
        var lastPickedNote: String? = nil
        var correctAnswersAtCurrentFret: Int = 0
        var answerBoxReady: Bool = false
        var pentatonicRevealCount: Int = 0
        var coursePhase: BeginnerCoursePhase = .round1Ascending
        var currentPhaseNumber: Int = 1
        var scaleRepetitionsRemaining: Int = 1
        var scaleSequenceIndex: Int = 0
        var scaleStageIndex: Int = 0
        var scaleCycleSemitoneOffset: Int = 0
        var pendingRewardStageAdvance: Bool = false
        var rewardTargetBeatPosition: Double? = nil
        var rewardSelectedString: Int? = nil
        var rewardNoteTextByString: [Int: String]? = nil
        var rewardScheduledStrings: [Int] = []
        var rewardScheduledMIDINotes: [Int] = []
        var rewardScheduledNoteTextByString: [Int: String] = [:]
        var rewardSustainMultiplier: Double = 3.0
        // Random style state
        var randomNoteSequence: [String] = []
        var usedNoteLocations: Set<String> = []
        var randomSequenceProgressIndex: Int = 0
        var randomRevealCount: Int = 0
        var randomRevealStartBeatBucket: Int? = nil
        // Sequential style state
        var sequentialRevealCount: Int = 0
        var sequentialRevealStartBeatBucket: Int? = nil
        // Round shift delay state
        var pendingRoundShiftBeatPosition: Double? = nil
        // Phase announcement timing state
        var phaseAnnouncementStartBeat: Double? = nil
        var phaseAnnouncementPhase: Int = 0 // 0=none, 1=phase number, 2=attributes, 3=completed
        // Phase transition state
        var phaseTransitionPending: Bool = false
        var nextPhaseNumber: Int = 1
        // Phase completed message state
        var phaseCompletedMessagePending: Bool = false
        var phaseCompletedMessageStartBeat: Double? = nil
        var completedPhaseNumber: Int = 0
        // MIDI stop delay state
        var pendingMidiStopDate: Date? = nil
        // Round counter (resets per phase, not tied to fret)
        var currentRoundInPhase: Int = 1
        // Wall-clock auto-advance from phase completed message to armed state
        var pendingPhaseCompletedAutoAdvanceDate: Date? = nil
    }

    private struct BeginnerRewardPolicyKey: Hashable {
        let stageIndex: Int
        let fret: Int?
    }

    private struct BeginnerRewardPolicy {
        let isRewardEnabled: Bool
        let delayBeats: Double
        let sustainMultiplier: Double
        let preferredStrings: [Int]?
    }

    @State private var startupSpeechPhase: StartupSpeechPhase = .idle
    @State private var availableBackingTracks: [BackingTrack] = []

    private let gameplayAudioEngine = GameplayAudioEngine()
    private let guitarNoteEngine: GuitarNotePlaying = GuitarNoteEngine.shared
    private let midiEngine: BackingTrackPlaying = SimpleMIDIEngine()
    private let audioEngineEnabled: Bool = false
    private let speakBeatTicks: Bool = false
    private let speakGameplayPrompts: Bool = false
    private let beginnerScaleTemplates: [BeginnerStageTemplate] = [
        BeginnerStageTemplate(root: "E", titleSuffix: "m Pentatonic", intervals: [0, 3, 5, 7, 10, 12], bassSemitoneTarget: 0, endsCycle: false),
        BeginnerStageTemplate(root: "E", titleSuffix: "MINOR", intervals: [0, 3, 7], bassSemitoneTarget: 0, endsCycle: false),
        BeginnerStageTemplate(root: "E", titleSuffix: "MINOR 7", intervals: [0, 3, 7, 10], bassSemitoneTarget: 0, endsCycle: false),
        BeginnerStageTemplate(root: "E", titleSuffix: "MINOR ADD 9", intervals: [0, 3, 5, 7], bassSemitoneTarget: 0, endsCycle: false),
        BeginnerStageTemplate(root: "E", titleSuffix: "MINOR ADD 11", intervals: [0, 5, 3, 7], bassSemitoneTarget: 0, endsCycle: false),
        BeginnerStageTemplate(root: "E", titleSuffix: "7 SUS 4", intervals: [0, 5, 7, 10], bassSemitoneTarget: 0, endsCycle: false),
        BeginnerStageTemplate(root: "E", titleSuffix: "MINOR 11", intervals: [0, 3, 5, 7, 10], bassSemitoneTarget: 0, endsCycle: false),
        BeginnerStageTemplate(root: "G", titleSuffix: "MAJOR", intervals: [0, 4, 7], bassSemitoneTarget: 3, endsCycle: false),
        BeginnerStageTemplate(root: "G", titleSuffix: "6", intervals: [0, 4, 7, 9], bassSemitoneTarget: 3, endsCycle: false),
        BeginnerStageTemplate(root: "G", titleSuffix: "ADD 9", intervals: [0, 2, 4, 7], bassSemitoneTarget: 3, endsCycle: false),
        BeginnerStageTemplate(root: "G", titleSuffix: "6/9", intervals: [0, 2, 4, 7, 9], bassSemitoneTarget: 3, endsCycle: false),
        BeginnerStageTemplate(root: "A", titleSuffix: "SUS 2", intervals: [0, 7, 2], bassSemitoneTarget: 5, endsCycle: false),
        BeginnerStageTemplate(root: "D", titleSuffix: "SUS 4", intervals: [0, 7, 5], bassSemitoneTarget: 10, endsCycle: true)
    ]

    private func beginnerChordSuffixDisplay(_ rawSuffix: String) -> String {
        switch rawSuffix {
        case "m Pentatonic": return "m Pentatonic"
        case "MINOR": return "m"
        case "MINOR 7": return "m7"
        case "MINOR ADD 9": return "madd9"
        case "MINOR ADD 11": return "madd11"
        case "7 SUS 4": return "7sus4"
        case "MINOR 11": return "m11"
        case "MAJOR": return "Maj"
        case "6": return "6"
        case "ADD 9": return "add9"
        case "6/9": return "6/9"
        case "SUS 2": return "sus2"
        case "SUS 4": return "sus4"
        default: return rawSuffix
        }
    }

    private var beginnerScaleStages: [BeginnerScaleStage] {
        beginnerScaleTemplates.map { template in
            let root = transposedNote(template.root, by: beginnerRuntime.scaleCycleSemitoneOffset, useFlats: beginnerUsesFlats)
            let notes = template.intervals.map { interval in
                transposedNote(template.root, by: beginnerRuntime.scaleCycleSemitoneOffset + interval, useFlats: beginnerUsesFlats)
            }
            let stageTitle = "\(root)\(beginnerChordSuffixDisplay(template.titleSuffix))"

            return BeginnerScaleStage(
                title: stageTitle,
                notes: notes,
                bassSemitoneTarget: template.bassSemitoneTarget + beginnerRuntime.scaleCycleSemitoneOffset,
                endsCycle: template.endsCycle
            )
        }
    }

    private var beginnerCurrentScaleStage: BeginnerScaleStage {
        let clampedIndex = min(max(beginnerRuntime.scaleStageIndex, 0), max(beginnerScaleStages.count - 1, 0))
        return beginnerScaleStages[clampedIndex]
    }

    private var beginnerCurrentScaleNotes: [String] {
        beginnerCurrentScaleStage.notes
    }

    private var beginnerCurrentScaleTitle: String {
        beginnerCurrentScaleStage.title
    }

    private var beginnerCurrentBassSemitoneTarget: Int {
        beginnerCurrentScaleStage.bassSemitoneTarget
    }

    private var beginnerRewardPolicies: [BeginnerRewardPolicyKey: BeginnerRewardPolicy] {
        var table: [BeginnerRewardPolicyKey: BeginnerRewardPolicy] = [:]
        let defaultPolicy = BeginnerRewardPolicy(
            isRewardEnabled: true,
            delayBeats: 3.0,
            sustainMultiplier: 3.0,
            preferredStrings: nil
        )
        for stageIndex in 1..<max(beginnerScaleStages.count, 1) {
            table[BeginnerRewardPolicyKey(stageIndex: stageIndex, fret: nil)] = defaultPolicy
        }
        return table
    }

    private var beginnerPentatonicProgressText: String {
        let notes = beginnerCurrentScaleNotes
        let count = min(max(beginnerRuntime.pentatonicRevealCount, 0), notes.count)
        return notes.prefix(count).joined(separator: " ")
    }

    private var beginnerCurrentRoundLabel: String {
        "BEGINNER ROUND \(beginnerRuntime.currentRoundInPhase)"
    }

    private var shouldShowLegacyRoundZeroIntro: Bool {
        beginnerRoundOneStartingFret == 0
    }

    private func getPhaseAttributes(for phaseNumber: Int) -> [String] {
        switch phaseNumber {
        case 1:
            return ["Sequential", "Low to High", "Ascending"]
        case 2:
            return ["Sequential", "Low to High", "Descending"]
        case 3:
            return ["Sequential", "High to Low", "Ascending"]
        case 4:
            return ["Sequential", "High to Low", "Descending"]
        case 5:
            return ["Chord", "Ascending"]
        case 6:
            return ["Chord", "Descending"]
        case 7:
            return ["Random", "Ascending"]
        case 8:
            return ["Random", "Descending"]
        default:
            return ["Sequential", "Low to High", "Ascending"]
        }
    }

    private func getPhaseAttributeColors(for phaseNumber: Int) -> [Color] {
        return [.green, .yellow, .orange, .white]
    }

    private func getPhaseNumberColor() -> Color {
        .cyan
    }

    private func getWalletColor() -> Color {
        .green
    }

    private func getRepetitionCountColor() -> Color {
        .pink
    }

    private var phaseAnnouncementText: AttributedString? {
        guard layoutMode == .beginner else { return nil }
        guard !isCodeScreensaverMode else { return nil }
        guard let startBeat = beginnerRuntime.phaseAnnouncementStartBeat else { return nil }

        let elapsedBeats = roundRevealElapsedBeats - startBeat
        let phaseNum = beginnerRuntime.currentPhaseNumber

        // Phase number display (beats 0-2)
        if elapsedBeats < 2.0 {
            var attributedString = AttributedString("PHASE \(phaseNum)")
            attributedString.foregroundColor = getPhaseNumberColor()
            return attributedString
        }

        // Attributes display (beats 2-8)
        if elapsedBeats < 8.0 {
            let attributeBeat = Int(floor(elapsedBeats - 2.0))
            let attributes = getPhaseAttributes(for: phaseNum)
            let colors = getPhaseAttributeColors(for: phaseNum)
            var attributedString = AttributedString("")

            // Phases 1-4 have 3 attributes, phases 5-8 have 2 attributes
            let hasThirdAttribute = attributes.count >= 3

            if attributeBeat >= 0 {
                attributedString += AttributedString(attributes[0])
                attributedString.foregroundColor = colors[0]
            }
            if attributeBeat >= 2, attributes.count >= 2 {
                attributedString += AttributedString("\n" + attributes[1])
                let range = attributedString.range(of: attributes[1])
                if let range = range {
                    attributedString[range].foregroundColor = colors[1]
                }
            }
            if attributeBeat >= 4, hasThirdAttribute {
                attributedString += AttributedString("\n" + attributes[2])
                let range = attributedString.range(of: attributes[2])
                if let range = range {
                    attributedString[range].foregroundColor = colors[2]
                }
            }
            return attributedString
        }

        return nil
    }

    private var phaseCompletedMessageText: AttributedString? {
        guard layoutMode == .beginner else { return nil }
        guard !isCodeScreensaverMode else { return nil }
        guard beginnerRuntime.phaseCompletedMessagePending else { return nil }
        guard let startBeat = beginnerRuntime.phaseCompletedMessageStartBeat else { return nil }

        let elapsedBeats = roundRevealElapsedBeats - startBeat
        let completedPhaseNum = beginnerRuntime.completedPhaseNumber

        // Show "PHASE N COMPLETED" for 14 beats
        if elapsedBeats < 14.0 {
            var attributedString = AttributedString("PHASE \(completedPhaseNum) COMPLETED")
            attributedString.foregroundColor = .green
            return attributedString
        }

        return nil
    }

    private var beginnerRoundStatusText: String? {
        guard layoutMode == .beginner else { return nil }

        // If phase announcement is active, return nil (will use phaseAnnouncementText instead)
        if beginnerRuntime.phaseAnnouncementStartBeat != nil {
            return nil
        }

        if beginnerRuntime.phaseCompletedMessagePending { return nil }

        // Random style: show revealed notes one by one on the beat
        if playLessonStyle == "random" {
            guard beginnerRuntime.currentPhaseNumber >= 1 && beginnerRuntime.currentPhaseNumber <= 8 else { return nil }
            guard !isCodeScreensaverMode else { return nil }

            let revealCount = min(beginnerRuntime.randomRevealCount, randomNoteGenerator.currentNoteSequence.count)
            let revealedNotes = randomNoteGenerator.currentNoteSequence.prefix(revealCount).joined(separator: " ")
            return revealedNotes
        }

        // Sequential style: show revealed notes one by one
        if playLessonStyle == "sequential" {
            guard !isCodeScreensaverMode else { return nil }

            let revealCount = min(beginnerRuntime.sequentialRevealCount, sequentialNoteGenerator.currentNoteSequence.count)
            let revealedNotes = sequentialNoteGenerator.currentNoteSequence.prefix(revealCount).joined(separator: " ")
            return revealedNotes
        }

        // Chord style: existing behavior
        // Odd phases (1,3,5,7) use ascending display logic
        if beginnerRuntime.currentPhaseNumber % 2 == 1 {
            if !beginnerRuntime.answerBoxReady,
               !beginnerRuntime.roundOneIntroActive {
                return nil
            }
            switch beginnerRoundZeroIntroDisplayPhase {
            case .centeredRoundZeroChordMode:
                return nil
            case .roundZeroHeader:
                return beginnerCurrentScaleTitle
            case .roundZeroScaleTitle:
                return beginnerCurrentScaleTitle
            case .noteReveal, .inactive:
                break
            }
            let progressLine = beginnerPentatonicProgressText
            if progressLine.isEmpty {
                return beginnerCurrentScaleTitle
            }
            return "\(beginnerCurrentScaleTitle)\n\(progressLine)"
        } else {
            // Even phases (2,4,6,8) - descending
            return "PHASE \(beginnerRuntime.currentPhaseNumber)"
        }
    }

    private var beginnerCenteredStatusMessage: String? {
        guard layoutMode == .beginner else { return nil }

        // Phase > 1: always show "PHASE N ARMED" regardless of lesson style
        if beginnerRuntime.currentPhaseNumber > 1 {
            if isCodeScreensaverMode && startupSequenceActivated {
                let startupState = StartupSequenceView.state(
                    for: startupSequenceElapsed,
                    showFullSequence: false,
                    armedText: beginnerStartupArmedText
                )
                if startupState.phase == .armed {
                    return "PHASE \(beginnerRuntime.currentPhaseNumber)\nARMED"
                }
            }
            return nil
        }

        // Random style: show intro message during startup
        if playLessonStyle == "random" {
            if isCodeScreensaverMode && startupSequenceActivated {
                let startupState = StartupSequenceView.state(
                    for: startupSequenceElapsed,
                    showFullSequence: false,
                    armedText: "RANDOM MODE ARMED"
                )
                if startupState.phase == .armed {
                    return "RANDOM MODE\nARMED"
                }
            }
            return nil
        }

        // Sequential style: show intro message during startup
        if playLessonStyle == "sequential" {
            if isCodeScreensaverMode && startupSequenceActivated {
                let startupState = StartupSequenceView.state(
                    for: startupSequenceElapsed,
                    showFullSequence: false,
                    armedText: "SEQUENTIAL MODE ARMED"
                )
                if startupState.phase == .armed {
                    return "SEQUENTIAL MODE\nARMED"
                }
            }
            return nil
        }

        return nil
    }

    private var beginnerCenteredStatusColor: Color {
        if playLessonStyle == "random" {
            return beginnerRuntime.celebrationFlashOn ? Color.green.opacity(0.98) : Color.green.opacity(0.28)
        }
        return beginnerRuntime.celebrationFlashOn ? Color.green.opacity(0.98) : Color.green.opacity(0.28)
    }

    private var beginnerRoundZeroIntroDisplayPhase: BeginnerRoundZeroIntroDisplayPhase {
        guard layoutMode == .beginner,
              beginnerRuntime.currentPhaseNumber >= 1 && beginnerRuntime.currentPhaseNumber <= 8,
              beginnerRuntime.roundOneIntroActive,
              beginnerRuntime.showRoundZeroIntroSequence
        else {
            return .inactive
        }

        let currentBeatBucket = Int(floor(roundRevealElapsedBeats))
        let startBeatBucket = beginnerRuntime.introStartBeatBucket ?? currentBeatBucket
        let elapsedBeatBuckets = max(currentBeatBucket - startBeatBucket, 0)

        if elapsedBeatBuckets < 2 {
            return .roundZeroHeader
        }
        if elapsedBeatBuckets < 4 {
            return .roundZeroScaleTitle
        }
        return .noteReveal
    }

    private var beginnerCelebrationActive: Bool {
        // Celebration is active when phase is complete but we're not transitioning
        // This is handled by phase transition state, not needed for gameplay guards
        false // Simplified - celebration state managed by transition logic
    }

    private var beginnerAcceptsGameplayAnswers: Bool {
        // Accept answers in all active gameplay phases (1-8)
        guard beginnerRuntime.currentPhaseNumber >= 1 && beginnerRuntime.currentPhaseNumber <= 8 else { return false }
        return !beginnerRuntime.roundOneIntroActive
    }

    private var playDirection: LessonDirection {
        LessonDirection(rawValue: playDirectionRawValue) ?? .ascending
    }

    private var effectivePlayRepetitions: Int {
        max(playRepetitions, 1)
    }

    private var beginnerRoundTwoStartsDescending: Bool {
        playDirection == .descending
    }

    private var beginnerLowerFretBoundary: Int {
        0
    }

    private var beginnerUpperFretBoundary: Int {
        playEnableHighFrets ? 19 : 12
    }

    private var clampedBeginnerStartingFret: Int {
        min(max(playStartingFret, beginnerLowerFretBoundary), beginnerUpperFretBoundary)
    }

    private var beginnerRoundTwoStartingFret: Int {
        clampedBeginnerStartingFret
    }

    private var beginnerRoundOneStartsDescending: Bool {
        playDirection == .descending
    }

    private var beginnerRoundOneStartingFret: Int {
        clampedBeginnerStartingFret
    }

    private var isInitialRoundOneScaleIntro: Bool {
        layoutMode == .beginner
            && beginnerRuntime.currentPhaseNumber == 1
            && beginnerRuntime.scaleStageIndex == 0
            && currentRound == beginnerRoundOneStartingFret
    }

    private var beginnerUsesFlats: Bool {
        guard layoutMode == .beginner else { return false }
        return isDescendingPhase
    }

    private var backingTrackShouldPlayInGameplay: Bool {
        guard layoutMode == .beginner else { return false }
        guard !isCodeScreensaverMode else { return false }
        return beginnerRuntime.currentPhaseNumber >= 1 && beginnerRuntime.currentPhaseNumber <= 8
    }

    private var startupStartButtonAttentionActive: Bool {
        guard layoutMode == .beginner else { return false }
        guard isCodeScreensaverMode else { return false }
        guard !isLaunchTransitionAnimating else { return false }

        if !startupSequenceActivated {
            return true
        }

        let startupState = StartupSequenceView.state(
            for: startupSequenceElapsed,
            showFullSequence: layoutMode != .beginner,
            armedText: beginnerStartupArmedText
        )
        return startupState.phase == .armed
    }

    private var backingTrackShouldBeActive: Bool {
        return backingTrackShouldPlayInGameplay
    }

    private var canPressStopButton: Bool {
        !isRoundArmed && !isCodeScreensaverMode && !isRoundPaused
    }

    private var canPressResetButton: Bool {
        !startupStartButtonAttentionActive
    }

    private var shouldLockPlayDirection: Bool {
        guard layoutMode == .beginner else { return false }
        return !isRoundArmed
    }

    private var beginnerStartupArmedText: String {
        // Any phase above 1 shows "PHASE N ARMED"
        if layoutMode == .beginner, beginnerRuntime.currentPhaseNumber > 1 {
            return "PHASE \(beginnerRuntime.currentPhaseNumber) ARMED"
        }
        if layoutMode == .beginner {
            if playLessonStyle == "sequential" { return "SEQUENTIAL MODE ARMED" }
            if playLessonStyle == "random" { return "RANDOM MODE ARMED" }
            return "CHORD MODE ARMED"
        }
        return "Memorization Sequence Armed"
    }

    init(
        onMenuSelection: ((GameplayMenuOption) -> Void)? = nil,
        selectedMode: RefretMode = .freestyle,
        selectedPhase: Int = 1,
        beatBPM: Int = 80,
        beatVolume: Double = 0.8,
        stringVolume: Double = 0.8,
        playStartingFret: Binding<Int> = .constant(0),
        playRepetitions: Binding<Int> = .constant(5),
        playDirectionRawValue: Binding<String> = .constant(LessonDirection.ascending.rawValue),
        playEnableHighFrets: Binding<Bool> = .constant(false),
        playLessonStyle: Binding<String> = .constant("chord"),
        walletDollars: Binding<Int> = .constant(0),
        balanceDollars: Binding<Int> = .constant(0)
    ) {
        self.onMenuSelection = onMenuSelection
        self.selectedMode = selectedMode
        self.selectedPhase = min(max(selectedPhase, 1), 8)
        self.beatBPM = beatBPM
        self.beatVolume = beatVolume
        self.stringVolume = stringVolume
        self._playStartingFret = playStartingFret
        self._playRepetitions = playRepetitions
        self._playDirectionRawValue = playDirectionRawValue
        self._playEnableHighFrets = playEnableHighFrets
        self._playLessonStyle = playLessonStyle
        self._walletDollars = walletDollars
        self._balanceDollars = balanceDollars
    }

    var body: some View {
        GeometryReader { proxy in
            let padding: CGFloat = 24
            let neckWidth = (proxy.size.width - padding * 2) * 0.8
            let fretRatios = FretMath.fretPositionRatios(totalFrets: totalFrets, scaleLength: scaleLengthInches)
            let visibleFrets = min(totalFrets, 5)
            let visibleFretIndex = min(visibleFrets, fretRatios.count - 1)
            let visibleRatio = max(fretRatios[visibleFretIndex], 0.05)
            let visibleClipHeight = proxy.size.height * 0.96
            let unclippedHeight = visibleClipHeight / visibleRatio
            let minimumNeckHeight = proxy.size.height * 1.35
            let neckHeight = max(unclippedHeight, minimumNeckHeight)
            let nutHeight = max(neckHeight * 0.02, 18)
            let nutVisualHeight = nutHeight * 0.4
            let debugGridColumns = 5
            let debugGridRows = 8
            let _ = proxy.size.width / CGFloat(debugGridColumns)
            let gridRowHeight = proxy.size.height / CGFloat(debugGridRows)
            let globalContentShiftY = gridRowHeight * 0.25
            let rowOneBottomLineY = gridRowHeight
            let highlightHeight = 2 * gridRowHeight
            let lockedWindowTopRowIndex: CGFloat = 1.0
            let highlightTopGridLineY = lockedWindowTopRowIndex * gridRowHeight
            
            let scale = displayScale
            
            let highlightCenterYSnapped: CGFloat = {
                let raw = highlightTopGridLineY + highlightHeight / 2
                return (raw * scale).rounded() / scale
            }()
            let viewingWindowShiftY: CGFloat = gridRowHeight * 0.5
            let viewingWindowCenterY = highlightCenterYSnapped + viewingWindowShiftY

            let pipingCenterY = viewingWindowCenterY
            let orangeGreenUnitCenterY = pipingCenterY - (gridRowHeight * 0.5)
            let holeCenterY = highlightCenterYSnapped
            let highlightAvailableWidth = max(proxy.size.width - padding * 2, 0)
            let highlightExtraWidth = max(highlightAvailableWidth - neckWidth, 0)
            let highlightWidth = neckWidth + highlightExtraWidth / 2
            let highlightCornerRadius = min(24, highlightWidth * 0.08)
            let currentTargetString = activeStringOrder[min(max(roundStringIndex, 0), activeStringOrder.count - 1)]
            let promptStrings = currentPromptStrings.isEmpty ? [currentTargetString] : currentPromptStrings
            let fretStatusLabel = currentRound == 0 ? "OPEN" : "FRET \(currentRound)"
            let stringStatusLabel = promptStrings.count > 1
                ? "STRINGS \(promptStrings.map(String.init).joined(separator: "+"))"
                : "STRING \(promptStrings[0])"
            let isGameplayStarted = !isCodeScreensaverMode
            let displayedFretStatusLabel = isGameplayStarted ? fretStatusLabel : ""
            let displayedStringStatusLabel: String = {
                if playLessonStyle == "random" { return "RANDOM STYLE" }
                if playLessonStyle == "sequential" { return "SEQUENTIAL MODE" }
                return isGameplayStarted ? stringStatusLabel : ""
            }()
            let roundStatusLabel = "ROUND \(beginnerRuntime.currentRoundInPhase)"
            let screenBannerFont = UIFont.systemFont(ofSize: 20, weight: .semibold)
            let screenMeasuredWidth = max(
                textWidth(for: fretStatusLabel, font: screenBannerFont),
                textWidth(for: stringStatusLabel, font: screenBannerFont),
                textWidth(for: "STRING 6", font: screenBannerFont)
            )
            let screenBannerWidth = screenMeasuredWidth + 32
            let screenBannerHeight = max(min(gridRowHeight * 0.72, 52), 44)
            let lowerScreenWidth = screenBannerWidth * 0.5
            let lowerScreenHeight = screenBannerHeight
            let thumbDiameter = min(proxy.size.width, proxy.size.height) * 0.336
            let virtualRows: CGFloat = 40
            let vRowH: CGFloat = proxy.size.height / virtualRows
            let buttonCenterY: CGFloat = (28 - 0.5) * vRowH
            let screenPairSpacing: CGFloat = 16
            let buttonPairSpacing: CGFloat = 28
            let windowBottomY = holeCenterY + highlightHeight / 2
            let topScreenY = windowBottomY + screenBannerHeight * 0.72
            let _ = (proxy.size.width / 2) - (screenBannerWidth / 2) - (screenPairSpacing / 2)
            let _ = (proxy.size.width / 2) + (screenBannerWidth / 2) + (screenPairSpacing / 2)
            let halfButtonCenterGap = (thumbDiameter + buttonPairSpacing) / 2
            let leftButtonCenterX = (proxy.size.width / 2) - halfButtonCenterGap
            let rightButtonCenterX = (proxy.size.width / 2) + halfButtonCenterGap
            let leftAnswerCenterX = leftButtonCenterX
            let rightAnswerCenterX = rightButtonCenterX
            let buttonTopY = buttonCenterY - (thumbDiameter / 2)
            let buttonBottomY = buttonCenterY + (thumbDiameter / 2)
            let whitePipingGap = max(gridRowHeight * 0.32, 14)
            let upperWhitePipingY = buttonTopY - whitePipingGap
            let lowerWhitePipingY = buttonBottomY + whitePipingGap - (gridRowHeight * 0.18)
            let transportCenterY = min(
                windowBottomY + max(gridRowHeight * 1.15, 24),
                upperWhitePipingY - max(gridRowHeight * 0.95, 20)
            )
            let whitePipingWidth = max(proxy.size.width - 7, 0)
            let noteChoiceY = upperWhitePipingY - (lowerScreenHeight / 2) - 2
            let windowTopY = holeCenterY - highlightHeight / 2
            let topStatusOuterWidth = highlightWidth
            let topStatusOuterHeight = max(min(gridRowHeight * 1.35, 120), 74)
            let topStatusBottomGap = max(gridRowHeight * 0.18, 10)
            let topStatusCenterY = (windowTopY - topStatusBottomGap) - (topStatusOuterHeight / 2)
            let sideWindowGap = max((proxy.size.width - highlightWidth) / 4, 18)
            let leftFretIndicatorX = (proxy.size.width / 2) - (highlightWidth / 2) - sideWindowGap
            let rightFretIndicatorX = (proxy.size.width / 2) + (highlightWidth / 2) + sideWindowGap
            let fretIndicatorText = "\(min(max(currentRound, 0), 12))"

            let unsignedN = abs(currentFretStart)
            let activeMidpointIndex: Int = {
                if currentFretStart > 0 {
                    return max(currentFretStart - 1, 0)
                }
                return unsignedN
            }()
            let clampedN = min(activeMidpointIndex, fretRatios.count - 2)
            let topRatio = fretRatios[clampedN]
            let bottomRatio = fretRatios[clampedN + 1]
            let midRatio = (topRatio + bottomRatio) / 2.0
            let sign: CGFloat = currentFretStart >= 0 ? 1.0 : -1.0
            let activeMidpoint = midRatio * neckHeight * sign
            
            let nutTargetY = baselineNutTargetY(highlightTopGridLineY: highlightTopGridLineY, gridRowHeight: gridRowHeight)
            let neckTopY = resolvedNeckTopY(
                currentFretStart: currentFretStart,
                nutTargetY: nutTargetY,
                highlightCenterY: pipingCenterY,
                activeMidpoint: activeMidpoint
            )
            
            let neckOffsetY: CGFloat = {
                if currentFretStart == 0 {
                    let raw = neckTopY - proxy.size.height / 2 + neckHeight / 2
                    return (raw * scale).rounded() / scale
                } else {
                    let raw = pipingCenterY - activeMidpoint - proxy.size.height / 2 + neckHeight / 2
                    return (raw * scale).rounded() / scale
                }
            }()
            
            let manualBlueAdjustment: CGFloat = -gridRowHeight * 0.5
            let finalNeckOffsetY = neckOffsetY + manualBlueAdjustment
            let neckVisualOffsetAdjustment = finalNeckOffsetY - neckOffsetY
            let nutBottomY = neckTopY + neckVisualOffsetAdjustment + (nutVisualHeight * 0.15)
            let stringStopInset = max(1.0, 2.0 / max(scale, 1.0))
            let stringTopY = nutBottomY + stringStopInset
            let calibratedAssetToNutDelta = assetToNutBottomDelta ?? 0
            let _ = (nutBottomY + calibratedAssetToNutDelta) - rowOneBottomLineY
            let startupState: (text: String, color: Color, isVisible: Bool, phase: StartupSequenceView.Phase) = {
                guard startupSequenceActivated else {
                    return ("", .clear, false, .systemOnline)
                }
                return StartupSequenceView.state(
                    for: startupSequenceElapsed,
                    showFullSequence: layoutMode != .beginner,
                    armedText: layoutMode == .beginner ? beginnerStartupArmedText : "Memorization Sequence Armed"
                )
            }()
            let screensaverThumbState: ThumbGlowState = {
                switch startupState.phase {
                case .systemOnline: return startupState.isVisible ? .orange : .neutral
                case .phaseOne: return startupState.isVisible ? .red : .neutral
                case .armed: return startupState.isVisible ? .green : .neutral
                }
            }()
            let effectiveLeftThumbState = isCodeScreensaverMode ? screensaverThumbState : leftThumbState
            let effectiveRightThumbState = isCodeScreensaverMode ? screensaverThumbState : rightThumbState
            let initialGameplayDimOpacity: CGFloat = (isCodeScreensaverMode && !startupSequenceActivated) ? 0.42 : 1.0

#if DEBUG
            let _ = { () -> Void in
                logAlignmentDiagnostics(
                    neckTopY: neckTopY,
                    activeMidpoint: activeMidpoint,
                    highlightCenterY: pipingCenterY,
                    highlightTopGridLineY: highlightTopGridLineY,
                    gridRowHeight: gridRowHeight
                )
            }()
#endif

            ZStack {
                FullScreenElephantBackground()
                    .ignoresSafeArea()

                HStack {
                    Spacer()
                    ZStack {
                        ZStack(alignment: .top) {
                            ZStack {
                                RosewoodSegmentedBackground(
                                    fretRatios: fretRatios,
                                    cornerRadius: 18
                                )
                                BindingLayer()
                                FretWireLayer(fretRatios: fretRatios)
                                FretMarkerLayer(fretRatios: fretRatios)
                            }
                            .frame(width: neckWidth, height: neckHeight)

                            NutLayer(width: neckWidth * 0.99, height: nutVisualHeight)
                                .frame(width: neckWidth * 0.99, height: nutVisualHeight)
                                .offset(y: -nutVisualHeight * 0.85)
                        }
                        .frame(width: neckWidth, height: neckHeight)
                        .offset(y: finalNeckOffsetY)
                    }
                    .frame(width: neckWidth, height: visibleClipHeight)
                    .clipped()
                    Spacer()
                }
                .padding(.horizontal, padding)
                .opacity(startupNeckVisualsHidden ? 0 : 1)

                StringLineOverlay(
                    neckWidth: neckWidth,
                    horizontalPadding: padding,
                    stringTopY: stringTopY
                )
                .opacity(startupNeckVisualsHidden ? 0 : 1)

                RoundedRectangle(cornerRadius: highlightCornerRadius, style: .continuous)
                    .fill(Color.black)
                    .frame(width: highlightWidth, height: highlightHeight)
                    .position(x: proxy.size.width / 2, y: pipingCenterY)
                    .allowsHitTesting(false)
                    .opacity(introWindowBlack ? 1 : 0)

                ElephantWindowView(
                    canvasSize: proxy.size,
                    highlightWidth: highlightWidth,
                    highlightHeight: highlightHeight,
                    highlightCenter: CGPoint(x: proxy.size.width / 2, y: orangeGreenUnitCenterY),
                    highlightCornerRadius: highlightCornerRadius
                )
                .allowsHitTesting(false)

                if isCodeScreensaverMode {
                    ZStack {
                        Image("REFRETLOGOSET")
                            .resizable()
                            .scaledToFill()
                            .scaleEffect(x: 1.15, y: 1.0, anchor: .center)
                            .frame(width: highlightWidth, height: highlightHeight)
                            .clipped()
                            .clipShape(HighlightWindowShape(cornerRadius: highlightCornerRadius))

                        HighlightWindowGoldBorder(
                            width: highlightWidth,
                            height: highlightHeight,
                            cornerRadius: highlightCornerRadius
                        )
                    }
                    .scaleEffect(isLaunchTransitionAnimating ? launchTileScale : 1)
                    .opacity(isLaunchTransitionAnimating ? launchTileOpacity : 1)
                    .position(x: proxy.size.width / 2, y: orangeGreenUnitCenterY)
                    .allowsHitTesting(false)
                }

                fretIndicatorOverlay(
                    leftX: leftFretIndicatorX,
                    rightX: rightFretIndicatorX,
                    centerY: orangeGreenUnitCenterY,
                    text: fretIndicatorText,
                    isHidden: isCodeScreensaverMode
                )

                if showFretboardGuide && !isCodeScreensaverMode {
                    let guideBoxHeight = topStatusOuterHeight * 0.5
                    let guideBoxWidth = neckWidth
                    let guideBoxCornerRadius = guideBoxHeight * 0.35
                    let guideBoxCenterY = windowBottomY - (guideBoxHeight / 2) - 4
                    let stringCenters = GuitarStringLayout.stringCenters(containerWidth: proxy.size.width, neckWidth: neckWidth)
                    let fretboardStrings = (0..<GuitarStringLayout.totalStrings).map { GuitarStringLayout.highestStringNumber - $0 }
                    let minGuideSpacing = zip(stringCenters.dropFirst(), stringCenters).map(-).min() ?? (guideBoxWidth / CGFloat(max(fretboardStrings.count, 1)))
                    let guideTileWidth = max(minGuideSpacing * 0.82, 18)
                    let guideTileHeight = guideBoxHeight * 0.86
                    ZStack {
                        // Six individual translucent backgrounds matching each note box
                        ForEach(Array(fretboardStrings.enumerated()), id: \.offset) { index, _ in
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.black.opacity(0.42))
                                .frame(width: guideTileWidth, height: guideTileHeight)
                                .position(x: stringCenters[index], y: guideBoxCenterY)
                        }

                        ForEach(Array(fretboardStrings.enumerated()), id: \.offset) { index, stringNumber in
                            let note = noteName(forString: stringNumber, fret: max(currentRound, 0), useFlats: beginnerUsesFlats)
                            let noteIsAccidental = note.contains("#") || note.contains("b")
                            let tileFill = noteIsAccidental ? Color.black.opacity(0.94) : Color.white.opacity(0.96)
                            let tileStroke = noteIsAccidental ? Color.white.opacity(0.7) : Color.black.opacity(0.68)
                            let textColor = noteIsAccidental ? Color.white.opacity(0.98) : Color.black.opacity(0.95)

                            RoundedRectangle(cornerRadius: guideBoxCornerRadius * 0.45, style: .continuous)
                                .fill(tileFill)
                                .overlay(
                                    RoundedRectangle(cornerRadius: guideBoxCornerRadius * 0.45, style: .continuous)
                                        .stroke(tileStroke, lineWidth: 1.2)
                                )
                                .frame(width: guideTileWidth, height: guideTileHeight)
                                .overlay {
                                    Text(note)
                                        .font(.system(size: guideBoxHeight * 0.48, weight: .black, design: .monospaced))
                                        .minimumScaleFactor(0.45)
                                        .lineLimit(1)
                                        .foregroundStyle(textColor)
                                }
                                .position(x: stringCenters[index], y: guideBoxCenterY)
                        }
                    }
                    .allowsHitTesting(false)
                }

                beatPulseOverlay(centerX: proxy.size.width / 2, centerY: topStatusCenterY, isHidden: isCodeScreensaverMode)

#if DEBUG
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .position(x: proxy.size.width / 2, y: holeCenterY)
                    .allowsHitTesting(false)
                    .opacity(0)
#endif

                DeveloperConsoleFrame(
                    width: topStatusOuterWidth,
                    height: topStatusOuterHeight,
                    isScreensaverMode: isCodeScreensaverMode,
                    layoutMode: layoutMode,
                    roundTitle: "\(phaseLabel) • \(roundStatusLabel)",
                    fretTitle: displayedFretStatusLabel,
                    stringTitle: displayedStringStatusLabel,
                    bankText: "$\(displayedBankDollars)",
                    highScoreText: "$\(highScoreDollars)",
                    scaleRepetitionText: "\(beginnerRuntime.scaleRepetitionsRemaining)X",
                    promptText: developerPromptText,
                    startupElapsed: startupSequenceElapsed,
                    showStartupSequence: startupSequenceActivated,
                    startupShowFullSequence: layoutMode != .beginner,
                    startupArmedText: beginnerStartupArmedText,
                    beginnerRoundStatusText: beginnerRoundStatusText,
                    phaseAnnouncementText: phaseAnnouncementText,
                    phaseCompletedMessageText: phaseCompletedMessageText,
                    celebrationActive: beginnerCelebrationActive,
                    celebrationFlashOn: beginnerRuntime.celebrationFlashOn,
                    centeredStatusMessage: beginnerCenteredStatusMessage,
                    centeredStatusColor: beginnerCenteredStatusColor,
                    currentRound: currentRound,
                    currentRoundInPhase: beginnerRuntime.currentRoundInPhase,
                    repetitionCountColor: getRepetitionCountColor(),
                    walletColor: getWalletColor()
                )
                .position(x: proxy.size.width / 2, y: topStatusCenterY)
                .allowsHitTesting(false)
                .opacity(codenameNemoEnabled ? 0 : 1)

                let introScale = max(questionBoxIntroProgress, 0.001)
                let introOffsetY = (1 - questionBoxIntroProgress) * ((proxy.size.height / 2) - topScreenY)
                let questionBoxOffsetY = (1 - questionBoxIntroProgress) * ((proxy.size.height / 2) - orangeGreenUnitCenterY)
                let shouldBlinkQuestionBox = false
                let shouldShowQuestionUI = !isCodeScreensaverMode && !startupSequenceActivated && questionBoxIntroProgress > 0.0
                let hasBeginnerSelectedNote = !(beginnerRuntime.lastPickedNote?.isEmpty ?? true)
                    || !(beginnerRuntime.rewardNoteTextByString?.isEmpty ?? true)
                let shouldShowWhiteAnswerBox = shouldShowQuestionUI && {
                    if layoutMode != .beginner { return true }
                    // Show answer box when note is selected, regardless of game state
                    if hasBeginnerSelectedNote && beginnerRuntime.answerBoxReady {
                        return true
                    }
                    // Random mode: answerBoxReady is set when all 6 notes revealed
                    if playLessonStyle == "random" {
                        return beginnerRuntime.answerBoxReady && hasBeginnerSelectedNote
                    }
                    // Chord mode: need pentatonic reveal complete
                    return beginnerRuntime.answerBoxReady
                        && beginnerRuntime.pentatonicRevealCount >= beginnerCurrentScaleNotes.count
                        && hasBeginnerSelectedNote
                }()

                if shouldShowQuestionUI {
                    HStack(spacing: screenPairSpacing) {
                        MiniTVFrame(
                            text: displayedStringStatusLabel,
                            width: screenBannerWidth,
                            height: screenBannerHeight,
                            fontScale: 0.82,
                            glowTint: questionBoxAssistActive ? .orange : nil,
                            hitTestingEnabled: false
                        )
                        MiniTVFrame(
                            text: displayedFretStatusLabel,
                            width: screenBannerWidth,
                            height: screenBannerHeight,
                            fontScale: 0.82,
                            glowTint: questionBoxAssistActive ? .orange : nil,
                            hitTestingEnabled: false
                        )
                    }
                    .scaleEffect(introScale)
                    .animation(.easeInOut(duration: 0.5), value: questionBoxIntroProgress)
                    .offset(y: introOffsetY)
                    .frame(width: proxy.size.width, height: screenBannerHeight)
                    .position(x: proxy.size.width / 2, y: topScreenY)
                    .allowsHitTesting(showMaestroOverlays)
                    .accessibilityHidden(!showMaestroOverlays)
                    .opacity(codenameNemoEnabled ? 0 : (showMaestroOverlays ? initialGameplayDimOpacity * introScale : 0))

                    MiniTVFrame(text: leftChoiceNote, width: lowerScreenWidth, height: lowerScreenHeight, fontScale: 1.0)
                        .position(x: leftAnswerCenterX, y: noteChoiceY)
                        .allowsHitTesting(false)
                        .accessibilityHidden(!showMaestroOverlays)
                        .opacity(codenameNemoEnabled ? 0 : (showMaestroOverlays ? introScale : 0))

                    MiniTVFrame(text: rightChoiceNote, width: lowerScreenWidth, height: lowerScreenHeight, fontScale: 1.0)
                        .position(x: rightAnswerCenterX, y: noteChoiceY)
                        .allowsHitTesting(false)
                        .accessibilityHidden(!showMaestroOverlays)
                        .opacity(codenameNemoEnabled ? 0 : (showMaestroOverlays ? introScale : 0))

                    if shouldShowWhiteAnswerBox {
                        WhiteNoteBoxOverlay(
                            centerY: orangeGreenUnitCenterY,
                            availableSize: proxy.size,
                            boxHeight: gridRowHeight * 0.9,
                            neckWidth: neckWidth,
                            activeStringNumbers: activePickedStringNumbers,
                            answerFeedback: activeAnswerFeedback,
                            blinkingActive: shouldBlinkQuestionBox,
                            blinkOrange: questionBoxPulsePhase,
                            revealedNoteText: layoutMode == .beginner
                                ? (hasBeginnerSelectedNote ? beginnerRuntime.lastPickedNote : nil)
                                : (activeAnswerFeedback == .green ? currentCorrectNote : nil),
                            revealedNoteTextByString: layoutMode == .beginner ? beginnerRuntime.rewardNoteTextByString : nil,
                            revealedNoteTextColor: Color.black.opacity(0.96)
                        )
                        .allowsHitTesting(false)
                        .offset(y: questionBoxOffsetY)
                        .opacity(codenameNemoEnabled ? 0 : initialGameplayDimOpacity)
                    }
                }

                GoldHorizontalPipingLine(width: whitePipingWidth)
                    .position(x: proxy.size.width / 2, y: upperWhitePipingY)
                    .allowsHitTesting(false)
                    .opacity(codenameNemoEnabled ? 0 : (showMaestroOverlays ? 1 : 0))

                GoldHorizontalPipingLine(width: whitePipingWidth)
                    .position(x: proxy.size.width / 2, y: lowerWhitePipingY)
                    .allowsHitTesting(false)
                    .opacity(codenameNemoEnabled ? 0 : (showMaestroOverlays ? 1 : 0))

                GoldPipingBorder(bottomInset: 0)
                    .allowsHitTesting(false)
                    .offset(y: -globalContentShiftY)
                    .zIndex(100)
            }
            .overlay(alignment: .bottom) {
                GameplayControlPlateShell(
                    isMenuExpanded: gameplayMenuExpanded,
                    isStartupInputLockActive: false,
                    isAutoplayActive: beginnerRuntime.autoPlayEnabled,
                    onAutoplay: {
                        beginnerRuntime.autoPlayEnabled.toggle()
                    },
                    onFretboard: {
                        handleFretboardButtonPress()
                    },
                    onToggleMenu: {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            gameplayMenuExpanded.toggle()
                        }
                    },
                    onSelectMenuOption: { option in
                        handleGameplayMenuSelection(option)
                    }
                )
                    .frame(maxWidth: min((proxy.size.width - 24) * 0.88, 370))
                    .padding(.bottom, 12)
                    .opacity(codenameNemoEnabled ? 0 : 1)
            }
            .overlay(alignment: .topLeading) {
                // No AUTO button overlay
            }
            .overlay(alignment: .topLeading) {
                HStack(spacing: 28) {
                    Button(action: { submitAnswer(.left) }) {
                        ThumbButtonView(
                            diameter: thumbDiameter,
                            label: "",
                            state: effectiveLeftThumbState
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isResolvingAnswer)

                    Button(action: { submitAnswer(.right) }) {
                        ThumbButtonView(
                            diameter: thumbDiameter,
                            label: "",
                            state: effectiveRightThumbState
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isResolvingAnswer)
                }
                .frame(maxWidth: .infinity)
                .position(x: proxy.size.width / 2, y: buttonCenterY)
                .allowsHitTesting(showMaestroOverlays)
                .accessibilityHidden(!showMaestroOverlays)
                .opacity(codenameNemoEnabled ? 0 : (showMaestroOverlays ? initialGameplayDimOpacity : 0))
            }
            .overlay(alignment: .topLeading) {
                if layoutMode == .beginner {
                    let beginnerButtonDiameter = min(max(proxy.size.width * 0.18, 66), 84) * 0.85
                    let beginnerButtonSpacing = beginnerButtonDiameter * 1.62
                    let rowYs = [buttonCenterY - beginnerButtonSpacing, buttonCenterY, buttonCenterY + beginnerButtonSpacing]
                    let leftButtonX = proxy.size.width * 0.2335
                    let rightButtonX = proxy.size.width * 0.7665
                    let beginnerScreenWidth = lowerScreenWidth * 0.54
                    let beginnerScreenHeight = lowerScreenHeight * 0.76
                    let noteScreenCenterYOffset = -beginnerButtonDiameter * 0.13
                    let screenInset = beginnerButtonDiameter * 0.88
                    let leftScreenX = leftButtonX + screenInset
                    let rightScreenX = rightButtonX - screenInset
                    let leftStrings = [4, 5, 6]
                    let rightStrings = [3, 2, 1]
                    let dThumbButtonY = rowYs[0]
                    let transportPanelCenterY = transportCenterY + 6
                    let beginnerBlueLightY = dThumbButtonY + ((transportPanelCenterY - dThumbButtonY) * 0.62)

                    ZStack {
                        ForEach(0..<3, id: \.self) { idx in
                            let selectedString = leftStrings[idx]
                            let buttonNote = noteName(forString: leftStrings[idx], fret: max(currentRound, 0), useFlats: beginnerUsesFlats)
                            let buttonIndex = idx
                            MiniTVFrame(
                                text: buttonNote,
                                width: beginnerScreenWidth,
                                height: beginnerScreenHeight,
                                fontScale: 1.0
                            )
                            .position(x: leftScreenX, y: rowYs[idx] + noteScreenCenterYOffset)

                            Button(action: {
                                handleBeginnerConsoleButtonPress(selectedNote: buttonNote, selectedString: selectedString, buttonIndex: buttonIndex)
                            }) {
                                ThumbButtonView(
                                    diameter: beginnerButtonDiameter,
                                    label: "",
                                    state: {
                                        if let pressedIndex = beginnerPressedButtonIndex, pressedIndex == buttonIndex {
                                            return beginnerPressedButtonCorrect ? .green : .red
                                        }
                                        if isCodeScreensaverMode && startupState.phase == .armed && startupState.isVisible {
                                            return .green
                                        }
                                        return .neutral
                                    }()
                                )
                            }
                            .buttonStyle(.plain)
                            .position(x: leftButtonX, y: rowYs[idx])
                        }

                        ForEach(0..<3, id: \.self) { idx in
                            let selectedString = rightStrings[idx]
                            let buttonNote = noteName(forString: rightStrings[idx], fret: max(currentRound, 0), useFlats: beginnerUsesFlats)
                            let buttonIndex = idx + 3
                            MiniTVFrame(
                                text: buttonNote,
                                width: beginnerScreenWidth,
                                height: beginnerScreenHeight,
                                fontScale: 1.0
                            )
                            .position(x: rightScreenX, y: rowYs[idx] + noteScreenCenterYOffset)

                            Button(action: {
                                handleBeginnerConsoleButtonPress(selectedNote: buttonNote, selectedString: selectedString, buttonIndex: buttonIndex)
                            }) {
                                ThumbButtonView(
                                    diameter: beginnerButtonDiameter,
                                    label: "",
                                    state: {
                                        if let pressedIndex = beginnerPressedButtonIndex, pressedIndex == buttonIndex {
                                            return beginnerPressedButtonCorrect ? .green : .red
                                        }
                                        if isCodeScreensaverMode && startupState.phase == .armed && startupState.isVisible {
                                            return .green
                                        }
                                        return .neutral
                                    }()
                                )
                            }
                            .buttonStyle(.plain)
                            .position(x: rightButtonX, y: rowYs[idx])
                        }

                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(red: 0.62, green: 0.86, blue: 1.0),
                                        Color(red: 0.09, green: 0.45, blue: 1.0)
                                    ],
                                    center: .center,
                                    startRadius: 0.5,
                                    endRadius: 10
                                )
                            )
                            .frame(width: 18, height: 18)
                            .shadow(color: Color(red: 0.28, green: 0.7, blue: 1.0).opacity(0.95), radius: 12)
                            .shadow(color: Color.white.opacity(0.45), radius: 5)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.75), lineWidth: 1)
                            )
                            .position(x: leftButtonX, y: beginnerBlueLightY)
                            .opacity(beginnerRuntime.beatLightFlashOn ? 1 : 0)
                            .animation(.easeOut(duration: 0.08), value: beginnerRuntime.beatLightFlashOn)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .allowsHitTesting(true)
                    .opacity(codenameNemoEnabled ? 0 : initialGameplayDimOpacity)
                    .accessibilityHidden(false)
                }
            }
            .overlay {
                HStack(spacing: 6) {
                    Button("START") { handleStartButtonPress() }
                        .frame(minWidth: 58, minHeight: 34, maxHeight: 34)
                        .background(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill((startupStartButtonAttentionActive && (!startupSequenceActivated ? startupStartButtonBlinkOn : startupState.isVisible))
                                    ? Color.green.opacity(0.9)
                                    : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                                        .stroke(Color.black.opacity(0.34), lineWidth: 1.0)
                                )
                        )
                    Button("STOP") { handleRoundStopButton() }
                        .frame(minWidth: 58, minHeight: 34, maxHeight: 34)
                        .disabled(!canPressStopButton)
                        .background(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .stroke(Color.black.opacity(0.34), lineWidth: 1.0)
                        )
                    Button("RESET") { handleRoundResetButton() }
                        .frame(minWidth: 58, minHeight: 34, maxHeight: 34)
                        .disabled(!canPressResetButton)
                        .background(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .stroke(Color.black.opacity(0.34), lineWidth: 1.0)
                        )
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
                                colors: [
                                    Color(red: 0.94, green: 0.82, blue: 0.53),
                                    Color(red: 0.78, green: 0.6, blue: 0.22),
                                    Color(red: 0.94, green: 0.82, blue: 0.53)
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
                .frame(width: min((proxy.size.width - 24) * 0.88, 370) * 0.72, height: 50)
                .position(x: proxy.size.width / 2, y: transportCenterY - 22)
                .opacity(codenameNemoEnabled ? 0 : 1)
            }
            .overlay {
                EmptyView()
            }
            .onAppear(perform: handleContentOnAppear)
            .onDisappear {
                midiEngine.stop()
            }
            .sheet(isPresented: $showAudioPage) {
                AudioPageView(
                    audioSettings: audioSettings,
                    availableBackingTracks: availableBackingTracks,
                    onDone: {
                        showAudioPage = false
                    }
                )
            }
            .onChange(of: audioSettings.guitarTonePreset) { _, newValue in
                guitarNoteEngine.configure(
                    preset: newValue,
                    reverbLevel: audioSettings.reverbLevel,
                    delayLevel: audioSettings.delayLevel
                )
            }
            .onChange(of: audioSettings.reverbLevel) { _, newValue in
                guitarNoteEngine.configure(
                    preset: audioSettings.guitarTonePreset,
                    reverbLevel: newValue,
                    delayLevel: audioSettings.delayLevel
                )
            }
            .onChange(of: audioSettings.delayLevel) { _, newValue in
                guitarNoteEngine.configure(
                    preset: audioSettings.guitarTonePreset,
                    reverbLevel: audioSettings.reverbLevel,
                    delayLevel: newValue
                )
            }
            .onChange(of: audioSettings.selectedBackingTrackID) { _, _ in
                syncBackingTrackPlayback()
            }
            .onChange(of: audioSettings.selectedBackingArrangement) { _, _ in
                syncBackingTrackPlayback()
            }
            .onChange(of: beginnerRuntime.coursePhase) { _, _ in
                applyBeginnerBassTransposeForCurrentStage()
                syncBackingTrackPlayback()
            }
            .onChange(of: beginnerRuntime.scaleStageIndex) { _, _ in
                applyBeginnerBassTransposeForCurrentStage()
            }
            .onChange(of: beginnerRuntime.scaleCycleSemitoneOffset) { _, _ in
                applyBeginnerBassTransposeForCurrentStage()
            }
            .onChange(of: isCodeScreensaverMode) { _, isScreensaverMode in
                updateDirectionLockState()
                syncBackingTrackPlayback()
                if isScreensaverMode {
                    beginnerRuntime.beatLightFlashOn = false
                    beginnerRuntime.beatLightLastProcessedBeat = nil
                    beginnerRuntime.beatLightIntroMeasureSkipped = false
                }
            }
            .onChange(of: currentRound) { _, newValue in
                _ = newValue
                applyBeginnerBassTransposeForCurrentStage()
            }
            .onChange(of: playRepetitions) { _, _ in
                guard layoutMode == .beginner else { return }

                if isRoundArmed || isRoundPaused {
                    beginnerRuntime.scaleRepetitionsRemaining = beginnerTargetScaleRepetitionsRemaining()
                    return
                }

                applyLivePlayRepetitionChangeIfNeeded()
            }
            .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { date in
                handleMainTimerTick(date)
            }
            .onChange(of: beginnerRuntime.autoPlayEnabled) { _, isEnabled in
                if layoutMode != .beginner {
                    beginnerRuntime.autoPlayEnabled = false
                    beginnerRuntime.autoPlayNextDate = nil
                    return
                }
                guard isEnabled else {
                    beginnerRuntime.autoPlayNextDate = nil
                    return
                }
                let revealReady = !beginnerRuntime.roundOneIntroActive
                    && beginnerRuntime.pentatonicRevealCount >= beginnerCurrentScaleNotes.count
                beginnerRuntime.autoPlayNextDate = revealReady ? Date().addingTimeInterval(0.2) : nil
            }
            .offset(y: globalContentShiftY)
        }
    }

    private func shiftFretSpan(by delta: Int) {
        guard delta != 0 else { return }
        withAnimation(.easeInOut(duration: 1.3)) {
            currentFretStart = min(max(currentFretStart + delta, minFretOffset), maxFretOffset)
        }
    }

    private func shiftWindow(by delta: Int) {
        let proposed = currentWindowRow + delta
        let clamped = min(max(proposed, 0), 7)
        guard clamped != currentWindowRow else { return }
        withAnimation(.easeInOut(duration: 0.45)) {
            currentWindowRow = clamped
        }
    }

    private func nextThumbState(after state: ThumbGlowState) -> ThumbGlowState {
        switch state {
        case .neutral: return .green
        case .orange: return .green
        case .green: return .red
        case .red: return .neutral
        }
    }
    private func fretIndicatorOverlay(leftX: CGFloat, rightX: CGFloat, centerY: CGFloat, text: String, isHidden: Bool) -> some View {
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

    private func beatPulseOverlay(centerX: CGFloat, centerY: CGFloat, isHidden: Bool) -> some View {
        Group {
            if !isHidden && modeVariant == .beat {
                Circle()
                    .fill(Color.green.opacity(beatPulseActive ? 0.86 : 0.22))
                    .frame(width: beatPulseActive ? 30 : 18, height: beatPulseActive ? 30 : 18)
                    .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1))
                    .position(x: centerX, y: centerY)
                    .animation(.easeInOut(duration: 0.16), value: beatPulseActive)
            }
        }
    }

    private func handleMainTimerTick(_ date: Date) {
        let shouldBlinkStartupStartButton = startupStartButtonAttentionActive && !startupSequenceActivated

        if shouldBlinkStartupStartButton {
            if startupStartButtonNextBlinkDate == nil {
                startupStartButtonBlinkOn = true
                startupStartButtonNextBlinkDate = date.addingTimeInterval(0.45)
            } else if let nextBlinkDate = startupStartButtonNextBlinkDate, date >= nextBlinkDate {
                startupStartButtonBlinkOn.toggle()
                startupStartButtonNextBlinkDate = date.addingTimeInterval(0.45)
            }
        } else {
            startupStartButtonBlinkOn = false
            startupStartButtonNextBlinkDate = nil
        }

        if startupSequenceActivated {
            startupSequenceElapsed = max(date.timeIntervalSince(startupSequenceStartDate), 0)
            let startupState = StartupSequenceView.state(for: startupSequenceElapsed, showFullSequence: layoutMode != .beginner, armedText: beginnerStartupArmedText)
            handleStartupSpeech(for: startupState.phase)
        }

        // Clear phase announcement after 8 beats
        if let startBeat = beginnerRuntime.phaseAnnouncementStartBeat {
            let elapsedBeats = roundRevealElapsedBeats - startBeat
            if elapsedBeats >= 8.0 {
                beginnerRuntime.phaseAnnouncementStartBeat = nil
                // Set roundOneIntroActive to trigger reveal pattern after phase announcement completes
                if layoutMode == .beginner && (playLessonStyle == "sequential" || playLessonStyle == "random" || playLessonStyle == "chord") {
                    beginnerRuntime.roundOneIntroActive = true
                    beginnerRuntime.roundOneSequenceStartDate = date
                    let currentBeatBucket = Int(floor(roundRevealElapsedBeats))
                    if playLessonStyle == "sequential" {
                        beginnerRuntime.sequentialRevealStartBeatBucket = currentBeatBucket
                    } else if playLessonStyle == "random" {
                        beginnerRuntime.randomRevealStartBeatBucket = currentBeatBucket
                    } else if playLessonStyle == "chord" {
                        beginnerRuntime.revealStartBeatBucket = currentBeatBucket
                    }
                }
            }
        }

        handlePendingMidiStopIfNeeded()

        // Auto-advance from phase completed message to next phase armed state (wall-clock, fires even while armed)
        if layoutMode == .beginner,
           let autoAdvanceDate = beginnerRuntime.pendingPhaseCompletedAutoAdvanceDate,
           date >= autoAdvanceDate {
            beginnerRuntime.pendingPhaseCompletedAutoAdvanceDate = nil
            beginnerRuntime.phaseCompletedMessagePending = false
            beginnerRuntime.phaseCompletedMessageStartBeat = nil
            advanceToNextPhaseArmedState()
        }

        if isRoundArmed || isRoundPaused {
            beginnerRuntime.beatLightFlashOn = false
            roundRevealLastTickDate = nil
            return
        }

        if roundRevealLastTickDate == nil {
            roundRevealLastTickDate = date
        } else if let lastTick = roundRevealLastTickDate {
            let delta = max(date.timeIntervalSince(lastTick), 0)
            let beatsPerSecond = Double(max(beatBPM, 60)) / 60.0
            roundRevealElapsedBeats += delta * beatsPerSecond
            roundRevealLastTickDate = date
        }

        handlePendingBeginnerRewardPlaybackIfNeeded()
        handlePendingRoundShiftIfNeeded()
        ensureBeginnerRoundOneRevealSequenceStarted(currentDate: date)
        updateBeginnerRoundOneRevealSequence(currentDate: date)
        updateRandomModeRevealProgressionIfNeeded()
        updateSequentialModeRevealProgressionIfNeeded()
        handleBeginnerAutoPlayIfNeeded(currentDate: date)

        let trackPlayingNow = midiEngine.isPlaying
        if isBackingTrackPlaying != trackPlayingNow {
            isBackingTrackPlaying = trackPlayingNow
        }

        let shouldRunBeatLight = layoutMode == .beginner && !isCodeScreensaverMode && trackPlayingNow
        if shouldRunBeatLight {
            let currentBeatBucket = Int(floor(midiEngine.currentBeatPosition()))

            if beginnerRuntime.beatLightLastProcessedBeat == nil {
                beginnerRuntime.beatLightLastProcessedBeat = currentBeatBucket
                beginnerRuntime.beatLightFlashOn = false
                return
            }

            if beginnerRuntime.beatLightLastProcessedBeat != currentBeatBucket {
                beginnerRuntime.beatLightLastProcessedBeat = currentBeatBucket

                if !beginnerRuntime.beatLightIntroMeasureSkipped {
                    if currentBeatBucket >= 4 {
                        beginnerRuntime.beatLightIntroMeasureSkipped = true
                    } else {
                        beginnerRuntime.beatLightFlashOn = false
                        return
                    }
                }

                beginnerRuntime.beatLightFlashOn = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    beginnerRuntime.beatLightFlashOn = false
                }
            }
        } else {
            beginnerRuntime.beatLightFlashOn = false
            beginnerRuntime.beatLightLastProcessedBeat = nil
            beginnerRuntime.beatLightIntroMeasureSkipped = false
        }
    }

    private func applyLivePlayRepetitionChangeIfNeeded() {
        guard layoutMode == .beginner,
              !isRoundArmed,
              !isRoundPaused
        else { return }

        guard beginnerRuntime.currentPhaseNumber >= 1 && beginnerRuntime.currentPhaseNumber <= 8 else {
            return
        }

        beginnerRuntime.scaleRepetitionsRemaining = beginnerTargetScaleRepetitionsRemaining()
    }

    private func beginnerTargetScaleRepetitionsRemaining() -> Int {
        // Even phases (2,4,6,8) are descending
        if beginnerRuntime.currentPhaseNumber % 2 == 0 {
            return max(effectivePlayRepetitions - beginnerRuntime.correctAnswersAtCurrentFret, 1)
        }
        return effectivePlayRepetitions
    }

    private func updateDirectionLockState() {
        directionLockActive = shouldLockPlayDirection
    }

    private func handleContentOnAppear() {
        initializeGameplaySession()
        updateDirectionLockState()
    }

    private func initializeGameplaySession() {
        audioSettings = AudioSettings()
        availableBackingTracks = BackingTrack.discoverBundledTracks()
        audioSettings.selectInitialBackingTrackIfNeeded(from: availableBackingTracks)
        guitarNoteEngine.configure(
            preset: audioSettings.guitarTonePreset,
            reverbLevel: audioSettings.reverbLevel,
            delayLevel: audioSettings.delayLevel
        )
        syncBackingTrackPlayback()
        if assetToNutBottomDelta == nil {
            assetToNutBottomDelta = 0
        }
        introDidRun = true
        startupSequenceStartDate = .now
        startupSequenceElapsed = 0
        startupSequenceActivated = false
        introWindowBlack = false
        currentFretStart = 0
        bankDollars = max(walletDollars, 0)
        displayedBankDollars = bankDollars
        showDeveloperPrompt("MODE: \(selectedMode.rawValue.uppercased())")
        questionBoxIntroProgress = isCodeScreensaverMode ? 0 : 1
        beginnerRuntime.answerBoxReady = layoutMode == .beginner ? false : !isCodeScreensaverMode
        beginnerRuntime.coursePhase = .round1Ascending
        isRoundArmed = layoutMode == .beginner
        isRoundPaused = false
        roundRevealElapsedBeats = 0
        roundRevealLastTickDate = nil
    }

    private func startGameFromBeginning(animateNeckSlideFromStartup: Bool = false) {
        if layoutMode == .beginner {
            // Phase 1 starts at open strings (fret 0), ascending
            if beginnerRuntime.currentPhaseNumber == 1 {
                currentRound = beginnerRoundOneStartingFret
                isDescendingPhase = beginnerRoundOneStartsDescending
            } else {
                // Other phases - set based on odd/even
                let isAscendingPhase = beginnerRuntime.currentPhaseNumber % 2 == 1
                currentRound = isAscendingPhase ? 0 : 12
                isDescendingPhase = !isAscendingPhase
            }
        } else {
            currentRound = isPhaseDescending ? 12 : 0
            isDescendingPhase = isPhaseDescending
        }
        if animateNeckSlideFromStartup {
            startupNeckVisualsHidden = true
            currentFretStart = isDescendingPhase ? maxFretOffset : minFretOffset
            DispatchQueue.main.async {
                startupNeckVisualsHidden = false
                withAnimation(.easeInOut(duration: 0.78)) {
                    currentFretStart = currentRound
                }
            }
        } else {
            startupNeckVisualsHidden = false
            currentFretStart = currentRound
        }
        roundStringIndex = 0
        bankDollars = 0
        displayedBankDollars = 0
        walletDollars = 0
        beatQuestionDeadline = nil
        currentPromptStrings = [1]
        activePickedStringNumbers = [1]
        beatCountInRemaining = modeVariant == .beat ? 4 : 0
        nextBeatTickDate = nil
        leftThumbState = .neutral
        rightThumbState = .neutral
        activeAnswerFeedback = nil
        isResolvingAnswer = false
        isRoundPaused = false
        roundRevealElapsedBeats = 0
        roundRevealLastTickDate = nil
        gameplayMenuExpanded = false
        developerPromptText = ""
        currentCorrectNote = ""
        lastResolvedCorrectNote = nil
        streakMeterLitColumns = 0
        streakMeterFailureActive = false
        streakMeterFailureVisibleColumns = 0
        beginnerRuntime.correctAnswersAtCurrentFret = 0
        lastPromptedCorrectNote = nil
        lastPromptedStringHalf = nil
        lastPromptedStringNumber = nil
        recentPromptedCorrectNotes = []
        beginnerRuntime.lastPickedNote = nil
        beginnerRuntime.rewardNoteTextByString = nil
        beginnerRuntime.answerBoxReady = layoutMode != .beginner
        beginnerRuntime.autoPlayNextDate = nil
        beginnerRuntime.celebrationFlashOn = false
        beginnerRuntime.celebrationNextFlashDate = nil
        beginnerRuntime.beatLightFlashOn = false
        beginnerRuntime.beatLightLastProcessedBeat = nil
        beginnerRuntime.roundOneIntroActive = false
        beginnerRuntime.roundOneSequenceStartDate = nil
        beginnerRuntime.beatLightIntroMeasureSkipped = false
        beginnerRuntime.scaleRepetitionsRemaining = effectivePlayRepetitions
        beginnerRuntime.currentRoundInPhase = 1
        beginnerRuntime.pendingRoundShiftBeatPosition = nil
        beginnerRuntime.scaleSequenceIndex = 0
        beginnerRuntime.scaleStageIndex = 0
        beginnerRuntime.scaleCycleSemitoneOffset = currentRound
        beginnerRuntime.pentatonicRevealCount = 0
        beginnerRuntime.revealStartBeatBucket = nil
        beginnerRuntime.introStartBeatBucket = nil
        beginnerRuntime.showRoundZeroIntroSequence = false
        beginnerRuntime.pendingRewardStageAdvance = false
        beginnerRuntime.rewardTargetBeatPosition = nil
        beginnerRuntime.rewardSelectedString = nil
        beginnerRuntime.rewardNoteTextByString = nil
        beginnerRuntime.rewardScheduledStrings = []
        beginnerRuntime.rewardScheduledMIDINotes = []
        beginnerRuntime.rewardScheduledNoteTextByString = [:]
        beginnerRuntime.rewardSustainMultiplier = 3.0

        // Initialize Random style state if needed
        if playLessonStyle == "random" {
            randomNoteGenerator.generateNoteSequence(for: currentRound, useFlats: beginnerUsesFlats)
            beginnerRuntime.randomRevealCount = 0
            beginnerRuntime.randomRevealStartBeatBucket = nil
            // Phase 1 has an announcement that will set roundOneIntroActive after 8 beats
            // Phases > 1 have no announcement, so set it now
            if beginnerRuntime.currentPhaseNumber > 1 {
                beginnerRuntime.roundOneIntroActive = true
                beginnerRuntime.roundOneSequenceStartDate = Date()
            }
        }

        // Initialize Sequential style state if needed
        if playLessonStyle == "sequential" {
            sequentialNoteGenerator.generateNoteSequence(for: currentRound, useFlats: beginnerUsesFlats, lowToHigh: beginnerRuntime.currentPhaseNumber <= 2)
            beginnerRuntime.sequentialRevealCount = 0
            beginnerRuntime.sequentialRevealStartBeatBucket = nil
            // Phase 1 has an announcement that will set roundOneIntroActive after 8 beats
            // Phases > 1 have no announcement, so set it now
            if beginnerRuntime.currentPhaseNumber > 1 {
                beginnerRuntime.roundOneIntroActive = true
                beginnerRuntime.roundOneSequenceStartDate = Date()
            }
        }

        applyBeginnerBassTransposeForCurrentStage()
        prepareCurrentQuestion()
    }

    private func beginnerRewardPolicyForCurrentStage() -> BeginnerRewardPolicy? {
        guard layoutMode == .beginner,
              beginnerRuntime.currentPhaseNumber >= 1 && beginnerRuntime.currentPhaseNumber <= 8
        else { return nil }

        let currentFret = max(currentRound, 0)
        let specificKey = BeginnerRewardPolicyKey(stageIndex: beginnerRuntime.scaleStageIndex, fret: currentFret)
        if let policy = beginnerRewardPolicies[specificKey], policy.isRewardEnabled {
            return policy
        }

        let fallbackKey = BeginnerRewardPolicyKey(stageIndex: beginnerRuntime.scaleStageIndex, fret: nil)
        if let policy = beginnerRewardPolicies[fallbackKey], policy.isRewardEnabled {
            return policy
        }

        return nil
    }

    private func beginnerRewardStringAssignments(forChordNotes chordNotes: [String], preferredStrings: [Int]?) -> [(Int, String)] {
        let allStringsDescending = [6, 5, 4, 3, 2, 1]
        let preferredSequence = preferredStrings ?? []
        let fallbackSequence = allStringsDescending.filter { !preferredSequence.contains($0) }
        let candidateSequence = preferredSequence + fallbackSequence
        let rewardDisplayFret = max(currentRound, 0)
        var unusedStrings = candidateSequence
        var assignments: [(Int, String)] = []
        let strictStringPriority = [1, 6, 5, 4, 3, 2]

        for chordNote in chordNotes {
            let matchingStrings = unusedStrings.filter {
                noteName(forString: $0, fret: rewardDisplayFret, useFlats: false) == chordNote
                    || noteName(forString: $0, fret: rewardDisplayFret, useFlats: beginnerUsesFlats) == chordNote
            }

            guard let matchedString = strictStringPriority.first(where: { matchingStrings.contains($0) }) else {
                continue
            }
            assignments.append((matchedString, chordNote))
            unusedStrings.removeAll { $0 == matchedString }
        }

        return assignments
    }

    private func beginnerRewardChordPayloadForCurrentStage(
        policy: BeginnerRewardPolicy
    ) -> (strings: [Int], notesByString: [Int: String], midiNotes: [Int]) {
        let chordNotes = Array(beginnerCurrentScaleNotes.prefix(5))
        let rewardPairs = beginnerRewardStringAssignments(forChordNotes: chordNotes, preferredStrings: policy.preferredStrings)

        var strings: [Int] = []
        var notesByString: [Int: String] = [:]
        var midiNotes: [Int] = []

        let rewardDisplayFret = max(currentRound, 0)

        for (stringNumber, _) in rewardPairs {
            let displayedNote = noteName(forString: stringNumber, fret: rewardDisplayFret, useFlats: beginnerUsesFlats)
            guard let midiNote = beginnerRewardMIDINote(for: displayedNote, stringNumber: stringNumber) else { continue }
            strings.append(stringNumber)
            notesByString[stringNumber] = displayedNote
            midiNotes.append(midiNote)
        }

        return (strings, notesByString, midiNotes)
    }

    private func beginnerRewardMIDINote(for noteName: String, stringNumber: Int) -> Int? {
        let openMIDINoteByString: [Int: Int] = [6: 40, 5: 45, 4: 50, 3: 55, 2: 59, 1: 64]
        guard let openMIDINote = openMIDINoteByString[stringNumber] else { return nil }

        let targetPitchClass = chromaticSharps.firstIndex(of: noteName)
            ?? chromaticFlats.firstIndex(of: noteName)
        guard let targetPitchClass else { return nil }

        let openPitchClass = openMIDINote % 12
        let fretOffset = (targetPitchClass - openPitchClass + 12) % 12
        return openMIDINote + fretOffset
    }

    private func scheduleBeginnerRewardChordThenAdvance(selectedString: Int, policy: BeginnerRewardPolicy) {
        let rewardPayload = beginnerRewardChordPayloadForCurrentStage(policy: policy)
        guard !rewardPayload.midiNotes.isEmpty else {
            advanceBeginnerScaleStage(afterCompletionFromString: selectedString, playTransitionNote: false)
            return
        }

        beginnerRuntime.pendingRewardStageAdvance = true
        beginnerRuntime.rewardSelectedString = selectedString
        beginnerRuntime.rewardTargetBeatPosition = roundRevealElapsedBeats + policy.delayBeats
        beginnerRuntime.rewardScheduledStrings = rewardPayload.strings
        beginnerRuntime.rewardScheduledMIDINotes = rewardPayload.midiNotes
        beginnerRuntime.rewardScheduledNoteTextByString = rewardPayload.notesByString
        beginnerRuntime.rewardSustainMultiplier = policy.sustainMultiplier
        beginnerRuntime.rewardNoteTextByString = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            guard beginnerRuntime.pendingRewardStageAdvance,
                  beginnerRuntime.rewardSelectedString == selectedString,
                  beginnerRuntime.rewardTargetBeatPosition != nil else { return }
            activePickedStringNumbers = []
            beginnerRuntime.lastPickedNote = nil
            beginnerRuntime.answerBoxReady = false
        }
    }

    private func scheduleBeginnerAdvanceAfterFinalNoteHold(selectedString: Int, holdSeconds: Double = 0.65) {
        beginnerRuntime.pendingRewardStageAdvance = true
        beginnerRuntime.rewardSelectedString = selectedString
        beginnerRuntime.rewardTargetBeatPosition = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + holdSeconds) {
            guard beginnerRuntime.pendingRewardStageAdvance,
                  beginnerRuntime.rewardSelectedString == selectedString,
                  beginnerRuntime.rewardTargetBeatPosition == nil else { return }
            beginnerRuntime.pendingRewardStageAdvance = false
            beginnerRuntime.rewardSelectedString = nil
            advanceBeginnerScaleStage(afterCompletionFromString: selectedString, playTransitionNote: false)
        }
    }

    private func handlePendingBeginnerRewardPlaybackIfNeeded() {
        guard beginnerRuntime.pendingRewardStageAdvance,
              let targetBeatPosition = beginnerRuntime.rewardTargetBeatPosition,
              let selectedString = beginnerRuntime.rewardSelectedString else { return }

        let currentBeatPosition = roundRevealElapsedBeats
        guard currentBeatPosition >= targetBeatPosition else { return }

        beginnerRuntime.rewardTargetBeatPosition = nil

        guard !beginnerRuntime.rewardScheduledMIDINotes.isEmpty else {
            beginnerRuntime.pendingRewardStageAdvance = false
            beginnerRuntime.rewardSelectedString = nil
            beginnerRuntime.rewardScheduledStrings = []
            beginnerRuntime.rewardScheduledMIDINotes = []
            beginnerRuntime.rewardScheduledNoteTextByString = [:]
            beginnerRuntime.rewardSustainMultiplier = 3.0
            advanceBeginnerScaleStage(afterCompletionFromString: selectedString, playTransitionNote: false)
            return
        }

        activePickedStringNumbers = beginnerRuntime.rewardScheduledStrings
        beginnerRuntime.answerBoxReady = true
        beginnerRuntime.lastPickedNote = nil
        beginnerRuntime.rewardNoteTextByString = beginnerRuntime.rewardScheduledNoteTextByString
        let rewardChordRingDuration = guitarNoteEngine.playChord(
            midiNotes: beginnerRuntime.rewardScheduledMIDINotes,
            velocity: 0.98,
            sustainMultiplier: beginnerRuntime.rewardSustainMultiplier
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + rewardChordRingDuration) {
            guard beginnerRuntime.pendingRewardStageAdvance,
                  beginnerRuntime.rewardSelectedString == selectedString else { return }
            beginnerRuntime.pendingRewardStageAdvance = false
            beginnerRuntime.rewardSelectedString = nil
            beginnerRuntime.rewardScheduledStrings = []
            beginnerRuntime.rewardScheduledMIDINotes = []
            beginnerRuntime.rewardScheduledNoteTextByString = [:]
            beginnerRuntime.rewardSustainMultiplier = 3.0
            advanceBeginnerScaleStage(afterCompletionFromString: selectedString, playTransitionNote: false)
        }
    }

    private func handlePendingRoundShiftIfNeeded() {
        guard (playLessonStyle == "random" || playLessonStyle == "sequential"),
              let targetBeatPosition = beginnerRuntime.pendingRoundShiftBeatPosition else { return }

        let currentBeatPosition = roundRevealElapsedBeats
        guard currentBeatPosition >= targetBeatPosition else { return }

        // 2-beat delay has passed - clear the pending shift and execute
        beginnerRuntime.pendingRoundShiftBeatPosition = nil

        // Clear white note box immediately before shift
        beginnerRuntime.lastPickedNote = nil
        beginnerRuntime.rewardNoteTextByString = nil
        beginnerRuntime.answerBoxReady = false

        // Reset mode state for new fret
        beginnerRuntime.scaleRepetitionsRemaining = effectivePlayRepetitions
        if playLessonStyle == "random" {
            randomNoteGenerator.resetForNewFret()
            beginnerRuntime.randomRevealCount = 0
            beginnerRuntime.randomRevealStartBeatBucket = nil
            beginnerRuntime.roundOneIntroActive = true
            beginnerRuntime.roundOneSequenceStartDate = Date()
        } else if playLessonStyle == "sequential" {
            sequentialNoteGenerator.resetForNewFret()
            beginnerRuntime.sequentialRevealCount = 0
            beginnerRuntime.sequentialRevealStartBeatBucket = nil
            beginnerRuntime.roundOneIntroActive = true
            beginnerRuntime.roundOneSequenceStartDate = Date()
        }

        // Advance to next fret (or celebrate if at boundary)
        if !isDescendingPhase {
            if currentRound < beginnerUpperFretBoundary {
                currentRound += 1
                beginnerRuntime.currentRoundInPhase += 1  // Increment round counter within phase
            } else {
                handlePhaseCompletion()
                return
            }
        } else {
            if currentRound > beginnerLowerFretBoundary {
                currentRound -= 1
                beginnerRuntime.currentRoundInPhase += 1  // Increment round counter within phase
            } else {
                handlePhaseCompletion()
                return
            }
        }

        // Generate new sequence for new fret and apply bass transpose
        let useFlats = layoutMode == .beginner ? beginnerUsesFlats : false
        if playLessonStyle == "random" {
            randomNoteGenerator.generateNoteSequence(for: max(currentRound, 0), useFlats: useFlats)
        } else if playLessonStyle == "sequential" {
            sequentialNoteGenerator.generateNoteSequence(for: max(currentRound, 0), useFlats: useFlats, lowToHigh: beginnerRuntime.currentPhaseNumber <= 2)
        }
        applyBeginnerBassTransposeForCurrentStage()
        prepareCurrentQuestion()
    }

    private func handlePendingMidiStopIfNeeded() {
        guard layoutMode == .beginner,
              let stopDate = beginnerRuntime.pendingMidiStopDate else { return }
        guard Date() >= stopDate else { return }

        // 3-beat delay has passed - stop the MIDI playback
        beginnerRuntime.pendingMidiStopDate = nil
        midiEngine.stop()
        isBackingTrackPlaying = false
    }

    private func advanceBeginnerScaleStage(afterCompletionFromString selectedString: Int, playTransitionNote: Bool = true) {
        let completedStageWasCycleEnd = beginnerCurrentScaleStage.endsCycle
        beginnerRuntime.rewardNoteTextByString = nil
        beginnerRuntime.rewardScheduledStrings = []
        beginnerRuntime.rewardScheduledMIDINotes = []
        beginnerRuntime.rewardScheduledNoteTextByString = [:]
        beginnerRuntime.rewardSustainMultiplier = 3.0
        beginnerRuntime.scaleRepetitionsRemaining = effectivePlayRepetitions
        if completedStageWasCycleEnd {
            let nextFret: Int?
            if isDescendingPhase {
                nextFret = currentRound > beginnerLowerFretBoundary ? currentRound - 1 : nil
            } else {
                nextFret = currentRound < beginnerUpperFretBoundary ? currentRound + 1 : nil
            }

            if let nextFret {
                beginnerRuntime.scaleCycleSemitoneOffset = nextFret
                beginnerRuntime.scaleStageIndex = 0
                beginnerRuntime.scaleSequenceIndex = 0
                beginnerRuntime.pentatonicRevealCount = 0
                beginnerRuntime.roundOneIntroActive = false
                beginnerRuntime.roundOneSequenceStartDate = nil
                beginnerRuntime.revealStartBeatBucket = nil
                beginnerRuntime.introStartBeatBucket = nil
                beginnerRuntime.pendingRewardStageAdvance = false
                beginnerRuntime.rewardSelectedString = nil
            }
        } else {
            beginnerRuntime.scaleStageIndex = min(beginnerRuntime.scaleStageIndex + 1, beginnerScaleStages.count - 1)
        }
        beginnerRuntime.scaleSequenceIndex = 0
        beginnerRuntime.pentatonicRevealCount = 0
        beginnerRuntime.roundOneIntroActive = true
        beginnerRuntime.roundOneSequenceStartDate = Date()
        roundRevealElapsedBeats = 0
        if playLessonStyle == "chord" {
            beginnerRuntime.showRoundZeroIntroSequence = true
            beginnerRuntime.introStartBeatBucket = 0
        }
        roundRevealLastTickDate = nil
        beginnerRuntime.answerBoxReady = false
        beginnerRuntime.lastPickedNote = nil
        applyBeginnerBassTransposeForCurrentStage()
        if playTransitionNote {
            playGuitarNote(forString: selectedString, fret: max(currentRound, 0), velocity: 0.98)
        }
    }

    private func transposedSharpNote(_ note: String, by semitones: Int) -> String {
        transposedNote(note, by: semitones, useFlats: false)
    }

    private func transposedNote(_ note: String, by semitones: Int, useFlats: Bool) -> String {
        guard let index = chromaticSharps.firstIndex(of: note) else { return note }
        let wrapped = (index + semitones % chromaticSharps.count + chromaticSharps.count) % chromaticSharps.count
        let scale = useFlats ? chromaticFlats : chromaticSharps
        return scale[wrapped]
    }

    private func applyBeginnerBassTransposeForCurrentStage() {
        guard layoutMode == .beginner else {
            midiEngine.setBassTransposeSemitones(0)
            return
        }

        // Odd phases (1,3,5,7) are ascending
        if beginnerRuntime.currentPhaseNumber % 2 == 1 {
            if playLessonStyle == "random" || playLessonStyle == "sequential" {
                // Random/Sequential style: transpose bass to match E string note at current fret
                // E string at fret 0 = E (MIDI 40), fret 1 = F (MIDI 41), etc.
                let transposeSemitones = max(currentRound, 0)
                midiEngine.setBassTransposeSemitones(transposeSemitones)
            } else {
                // Chord style: existing behavior
                midiEngine.setBassTransposeSemitones(beginnerCurrentBassSemitoneTarget)
            }
            return
        }

        // Even phases (2,4,6,8) are descending
        if beginnerRuntime.currentPhaseNumber % 2 == 0 {
            midiEngine.setBassTransposeSemitones(max(currentRound, 0) % 12)
            return
        }

        midiEngine.setBassTransposeSemitones(0)
    }

    private func ensureBeginnerRoundOneRevealSequenceStarted(currentDate: Date) {
        guard layoutMode == .beginner,
              beginnerRuntime.currentPhaseNumber >= 1 && beginnerRuntime.currentPhaseNumber <= 8,
              !isCodeScreensaverMode,
              !startupSequenceActivated,
              playLessonStyle == "chord",
              questionBoxIntroProgress > 0,
              beginnerRuntime.roundOneSequenceStartDate == nil,
              beginnerRuntime.pentatonicRevealCount == 0,
              !beginnerRuntime.answerBoxReady,
              !isRoundArmed
        else { return }

        beginnerRuntime.roundOneIntroActive = true
        beginnerRuntime.roundOneSequenceStartDate = currentDate
        beginnerRuntime.pentatonicRevealCount = 0
        beginnerRuntime.revealStartBeatBucket = nil
        beginnerRuntime.introStartBeatBucket = Int(floor(roundRevealElapsedBeats))
        beginnerRuntime.showRoundZeroIntroSequence = playLessonStyle == "chord" ? true : shouldShowLegacyRoundZeroIntro
        beginnerRuntime.lastPickedNote = nil
        beginnerRuntime.answerBoxReady = false
    }

    private func updateBeginnerRoundOneRevealSequence(currentDate _: Date) {
        guard beginnerRuntime.roundOneIntroActive,
              beginnerRuntime.roundOneSequenceStartDate != nil,
              layoutMode == .beginner,
              playLessonStyle == "chord",
              !isCodeScreensaverMode,
              !startupSequenceActivated
        else { return }

        guard beginnerRoundZeroIntroDisplayPhase == .noteReveal else { return }
        let currentBeatBucket = Int(floor(roundRevealElapsedBeats))
        if beginnerRuntime.revealStartBeatBucket == nil {
            beginnerRuntime.revealStartBeatBucket = currentBeatBucket
        }
        let revealStartBeatBucket = beginnerRuntime.revealStartBeatBucket ?? currentBeatBucket
        let elapsedBeatBuckets = max(currentBeatBucket - revealStartBeatBucket, 0)
        let revealedCount: Int = {
            guard elapsedBeatBuckets >= 0 else { return 0 }
            return elapsedBeatBuckets + 1
        }()
        let clampedRevealCount = min(max(revealedCount, 0), beginnerCurrentScaleNotes.count)

        if clampedRevealCount != beginnerRuntime.pentatonicRevealCount {
            beginnerRuntime.pentatonicRevealCount = clampedRevealCount
        }

        if clampedRevealCount >= beginnerCurrentScaleNotes.count {
            beginnerRuntime.roundOneIntroActive = false
            beginnerRuntime.roundOneSequenceStartDate = nil
            beginnerRuntime.revealStartBeatBucket = nil
            beginnerRuntime.introStartBeatBucket = nil
            beginnerRuntime.showRoundZeroIntroSequence = false
            beginnerRuntime.answerBoxReady = true
        }
    }

    private func updateRandomModeRevealProgressionIfNeeded() {
        guard layoutMode == .beginner,
              playLessonStyle == "random",
              beginnerRuntime.currentPhaseNumber >= 1 && beginnerRuntime.currentPhaseNumber <= 8,
              !isCodeScreensaverMode,
              !startupSequenceActivated
        else { return }

        let currentBeatBucket = Int(floor(roundRevealElapsedBeats))
        if beginnerRuntime.randomRevealStartBeatBucket == nil {
            beginnerRuntime.randomRevealStartBeatBucket = currentBeatBucket
        }
        let revealStartBeatBucket = beginnerRuntime.randomRevealStartBeatBucket ?? currentBeatBucket
        let elapsedBeatBuckets = max(currentBeatBucket - revealStartBeatBucket, 0)

        let revealedCount: Int = {
            guard elapsedBeatBuckets >= 0 else { return 0 }
            return elapsedBeatBuckets + 1
        }()
        let clampedRevealCount = min(max(revealedCount, 0), 6)

        if clampedRevealCount != beginnerRuntime.randomRevealCount {
            beginnerRuntime.randomRevealCount = clampedRevealCount
        }

        if clampedRevealCount >= 6 {
            beginnerRuntime.answerBoxReady = true
        }
        // Clear the intro gate one beat after the 6th note appears so autoplay waits for full display
        if elapsedBeatBuckets >= 6 {
            beginnerRuntime.roundOneIntroActive = false
            beginnerRuntime.roundOneSequenceStartDate = nil
        }
    }

    private func updateSequentialModeRevealProgressionIfNeeded() {
        guard layoutMode == .beginner,
              playLessonStyle == "sequential",
              beginnerRuntime.currentPhaseNumber >= 1 && beginnerRuntime.currentPhaseNumber <= 8,
              !isCodeScreensaverMode,
              !startupSequenceActivated
        else { return }

        let currentBeatBucket = Int(floor(roundRevealElapsedBeats))
        if beginnerRuntime.sequentialRevealStartBeatBucket == nil {
            beginnerRuntime.sequentialRevealStartBeatBucket = currentBeatBucket
        }
        let revealStartBeatBucket = beginnerRuntime.sequentialRevealStartBeatBucket ?? currentBeatBucket
        let elapsedBeatBuckets = max(currentBeatBucket - revealStartBeatBucket, 0)

        let revealedCount: Int = {
            guard elapsedBeatBuckets >= 0 else { return 0 }
            return elapsedBeatBuckets + 1
        }()
        let clampedRevealCount = min(max(revealedCount, 0), 6)

        if clampedRevealCount != beginnerRuntime.sequentialRevealCount {
            beginnerRuntime.sequentialRevealCount = clampedRevealCount
        }

        if clampedRevealCount >= 6 {
            beginnerRuntime.answerBoxReady = true
        }
        // Clear the intro gate one beat after the 6th note appears so autoplay waits for full display
        if elapsedBeatBuckets >= 6 {
            beginnerRuntime.roundOneIntroActive = false
            beginnerRuntime.roundOneSequenceStartDate = nil
            // Note: sequentialRevealStartBeatBucket is NOT reset here - it will be reset when starting new round
        }
    }

    private func handleBeginnerAutoPlayIfNeeded(currentDate: Date) {
        guard layoutMode == .beginner,
              beginnerRuntime.autoPlayEnabled,
              !isCodeScreensaverMode,
              !startupSequenceActivated,
              !isResolvingAnswer,
              !beginnerRuntime.pendingRewardStageAdvance,
              beginnerRuntime.pendingRoundShiftBeatPosition == nil
        else {
            if layoutMode != .beginner || !beginnerRuntime.autoPlayEnabled {
                beginnerRuntime.autoPlayNextDate = nil
            }
            return
        }

        let fret = max(currentRound, 0)

        if playLessonStyle == "random" {
            guard beginnerRuntime.currentPhaseNumber >= 1 && beginnerRuntime.currentPhaseNumber <= 8 else {
                beginnerRuntime.autoPlayNextDate = nil
                return
            }
            guard beginnerRuntime.randomRevealCount >= 6 else {
                beginnerRuntime.autoPlayNextDate = nil
                return
            }
            // Wait until all 6 notes have been visible for at least 1 full beat
            let randomRevealElapsed = Int(floor(roundRevealElapsedBeats)) - (beginnerRuntime.randomRevealStartBeatBucket ?? Int(floor(roundRevealElapsedBeats)))
            guard randomRevealElapsed >= 7 else {
                beginnerRuntime.autoPlayNextDate = nil
                return
            }
            guard !randomNoteGenerator.isSequenceComplete() else {
                beginnerRuntime.autoPlayNextDate = nil
                return
            }
            guard let nextString = randomNoteGenerator.expectedString,
                  let nextNote = randomNoteGenerator.currentNoteSequence.indices.contains(randomNoteGenerator.sequenceProgressIndex)
                    ? Optional(randomNoteGenerator.currentNoteSequence[randomNoteGenerator.sequenceProgressIndex])
                    : nil
            else {
                beginnerRuntime.autoPlayNextDate = nil
                return
            }
            // Use the exact string the sequence demands — no guessing
            if beginnerRuntime.autoPlayNextDate == nil {
                beginnerRuntime.autoPlayNextDate = currentDate.addingTimeInterval(0.38)
                return
            }
            guard let nextDate = beginnerRuntime.autoPlayNextDate, currentDate >= nextDate else { return }
            let buttonIndex = nextString >= 4 ? (nextString - 4) : (6 - nextString)
            handleBeginnerConsoleButtonPress(selectedNote: nextNote, selectedString: nextString, buttonIndex: buttonIndex)
            beginnerRuntime.autoPlayNextDate = currentDate.addingTimeInterval(0.38)
            return
        }

        if playLessonStyle == "sequential" {
            guard beginnerRuntime.currentPhaseNumber >= 1 && beginnerRuntime.currentPhaseNumber <= 8 else {
                beginnerRuntime.autoPlayNextDate = nil
                return
            }
            guard beginnerRuntime.sequentialRevealCount >= 6 else {
                beginnerRuntime.autoPlayNextDate = nil
                return
            }
            // Wait until all 6 notes have been visible for at least 1 full beat
            let seqRevealElapsed = Int(floor(roundRevealElapsedBeats)) - (beginnerRuntime.sequentialRevealStartBeatBucket ?? Int(floor(roundRevealElapsedBeats)))
            guard seqRevealElapsed >= 7 else {
                beginnerRuntime.autoPlayNextDate = nil
                return
            }
            guard !sequentialNoteGenerator.isSequenceComplete() else {
                beginnerRuntime.autoPlayNextDate = nil
                return
            }
            guard let nextString = sequentialNoteGenerator.expectedString,
                  let nextNote = sequentialNoteGenerator.currentNoteSequence.indices.contains(sequentialNoteGenerator.sequenceProgressIndex)
                    ? Optional(sequentialNoteGenerator.currentNoteSequence[sequentialNoteGenerator.sequenceProgressIndex])
                    : nil
            else {
                beginnerRuntime.autoPlayNextDate = nil
                return
            }
            // Use the exact string the sequence demands — no guessing
            if beginnerRuntime.autoPlayNextDate == nil {
                beginnerRuntime.autoPlayNextDate = currentDate.addingTimeInterval(0.38)
                return
            }
            guard let nextDate = beginnerRuntime.autoPlayNextDate, currentDate >= nextDate else { return }
            let buttonIndex = nextString >= 4 ? (nextString - 4) : (6 - nextString)
            handleBeginnerConsoleButtonPress(selectedNote: nextNote, selectedString: nextString, buttonIndex: buttonIndex)
            beginnerRuntime.autoPlayNextDate = currentDate.addingTimeInterval(0.38)
            return
        } else {
            // Chord style: existing behavior
            // Chord mode active in phases 5-6
            guard playLessonStyle == "chord",
                  !beginnerRuntime.roundOneIntroActive,
                  beginnerRuntime.pentatonicRevealCount >= beginnerCurrentScaleNotes.count,
                  !beginnerCurrentScaleNotes.isEmpty
            else {
                beginnerRuntime.autoPlayNextDate = nil
                return
            }
            let safeSequenceIndex = min(max(beginnerRuntime.scaleSequenceIndex, 0), beginnerCurrentScaleNotes.count - 1)
            if safeSequenceIndex != beginnerRuntime.scaleSequenceIndex {
                beginnerRuntime.scaleSequenceIndex = safeSequenceIndex
            }
            let expectedNote = beginnerCurrentScaleNotes[safeSequenceIndex]

            if beginnerRuntime.autoPlayNextDate == nil {
                beginnerRuntime.autoPlayNextDate = currentDate.addingTimeInterval(0.38)
                return
            }
            guard let nextDate = beginnerRuntime.autoPlayNextDate, currentDate >= nextDate else { return }
            let preferredStringOrder = beginnerAutoPlayPreferredStringOrder(for: expectedNote)
            let matchedString = preferredStringOrder.first {
                noteName(forString: $0, fret: fret, useFlats: false) == expectedNote
            } ?? preferredStringOrder.first {
                noteName(forString: $0, fret: fret, useFlats: beginnerUsesFlats) == expectedNote
            }
            guard let selectedString = matchedString else {
                beginnerRuntime.autoPlayNextDate = currentDate.addingTimeInterval(0.38)
                return
            }
            let buttonIndex = selectedString <= 3 ? (6 - selectedString) : (selectedString - 4)
            handleBeginnerConsoleButtonPress(selectedNote: expectedNote, selectedString: selectedString, buttonIndex: buttonIndex)
            beginnerRuntime.autoPlayNextDate = currentDate.addingTimeInterval(0.38)
        }
    }

    private func beginnerAutoPlayPreferredStringOrder(for expectedNote: String) -> [Int] {
        let lowToHigh = [6, 5, 4, 3, 2, 1]
        let highToLow = [1, 2, 3, 4, 5, 6]
        let stageTitle = beginnerCurrentScaleStage.title.uppercased()
        let stageTokens = stageTitle.split(separator: " ")
        let stageRoot = stageTokens.first.map(String.init) ?? ""

        if stageTitle.hasPrefix("G ") && expectedNote == "E" {
            return highToLow
        }

        let isFinalNoteInStage = beginnerRuntime.scaleSequenceIndex == max(beginnerCurrentScaleNotes.count - 1, 0)
        if stageTitle.contains("MINOR PENTATONIC")
            && !stageRoot.isEmpty
            && expectedNote == stageRoot
            && isFinalNoteInStage {
            return highToLow
        }

        return lowToHigh
    }

    private func submitAnswer(_ side: AnswerSide, force: Bool = false) {
        if layoutMode == .beginner && isRoundArmed {
            handleRoundStartButton()
            return
        }
        if layoutMode == .beginner && isRoundPaused {
            return
        }
        if isCodeScreensaverMode {
            if !startupSequenceActivated {
                startupSequenceActivated = true
                startupSequenceStartDate = .now
                startupSequenceElapsed = 0
                startupSpeechPhase = layoutMode == .beginner ? .pendingArmed : .pendingSystem
                questionBoxIntroProgress = 0
                return
            }

            let startupState = StartupSequenceView.state(
                for: startupSequenceElapsed,
                showFullSequence: layoutMode != .beginner,
                armedText: beginnerStartupArmedText
            )
            guard startupState.phase == .armed else { return }
            guard !isLaunchTransitionAnimating else { return }

            isLaunchTransitionAnimating = true
            startupNeckVisualsHidden = true
            launchTileScale = 1
            launchTileOpacity = 1
            withAnimation(.easeIn(duration: 0.4725)) {
                launchTileScale = 0.1
                launchTileOpacity = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4725) {
                isCodeScreensaverMode = false
                startupSequenceActivated = false
                startupSequenceElapsed = 0
                startupSpeechPhase = .idle
                startGameFromBeginning(animateNeckSlideFromStartup: true)
                isLaunchTransitionAnimating = false
                launchTileScale = 1
                launchTileOpacity = 1
                withAnimation(.easeOut(duration: 0.6)) {
                    questionBoxIntroProgress = 1
                }
            }
            return
        }

        if isRoundPaused {
            return
        }

        if layoutMode == .beginner {
            return
        }

        guard force || !isResolvingAnswer else { return }
        isResolvingAnswer = true
        beatQuestionDeadline = nil
        playCurrentPromptedGuitarNotes(velocity: force ? 0.82 : 0.94)

        let isCorrect = side == correctAnswerSide
        if isCorrect {
            if side == .left {
                leftThumbState = .green
            } else {
                rightThumbState = .green
            }
            activeAnswerFeedback = .green
            lastResolvedCorrectNote = currentCorrectNote
            lastResolvedCorrectString = currentPromptStrings.first
        } else {
            if side == .left {
                leftThumbState = .red
            } else {
                rightThumbState = .red
            }
            activeAnswerFeedback = .red
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            leftThumbState = .neutral
            rightThumbState = .neutral
            questionBoxAssistActive = false
            if isCorrect {
                isResolvingAnswer = false
                advanceGame(afterCorrectAnswer: true)
            } else {
                advanceGame(afterCorrectAnswer: false)
            }
        }
    }

    private func advanceGame(afterCorrectAnswer isCorrect: Bool) {
        if !isCorrect {
            isResolvingAnswer = false
            prepareCurrentQuestion()
            return
        }

        beginnerRuntime.correctAnswersAtCurrentFret = min(beginnerRuntime.correctAnswersAtCurrentFret + 1, 20)
        let payout = payoutForRound(currentRound)
        bankDollars += payout
        displayedBankDollars = bankDollars
        walletDollars = bankDollars
        balanceDollars += payout
        highScoreDollars = max(highScoreDollars, bankDollars)

        if layoutMode == .beginner {
            // Even phases (2,4,6,8) are descending
            if beginnerRuntime.currentPhaseNumber % 2 == 0 {
                let requiredCorrectAnswers = effectivePlayRepetitions
                let completedAtCurrentFret = beginnerRuntime.correctAnswersAtCurrentFret

                if completedAtCurrentFret >= requiredCorrectAnswers {
                    beginnerRuntime.correctAnswersAtCurrentFret = 0
                    // Reset repetitions for the new chord after this note completes
                    // This will be set in the advance logic, not here

                    if beginnerRoundTwoStartsDescending {
                        if currentRound > beginnerLowerFretBoundary {
                            currentRound -= 1
                            prepareCurrentQuestion()
                        } else {
                            beginBeginnerRoundTwoCelebration()
                            return
                        }
                    } else {
                        if currentRound < beginnerUpperFretBoundary {
                            currentRound += 1
                            prepareCurrentQuestion()
                        } else {
                            beginBeginnerRoundTwoCelebration()
                            return
                        }
                    }
                    
                    // Reset repetitions for the new chord
                    beginnerRuntime.scaleRepetitionsRemaining = requiredCorrectAnswers
                } else {
                    beginnerRuntime.scaleRepetitionsRemaining = max(requiredCorrectAnswers - completedAtCurrentFret, 1)
                }
            }

            prepareCurrentQuestion()
            return
        }

        if usesRandomStringOrder {
            roundStringIndex = Int.random(in: 0..<max(activeStringOrder.count, 1))
        } else if roundStringIndex < activeStringOrder.count - 1 {
            roundStringIndex += 1
        } else {
            roundStringIndex = 0
            if !isDescendingPhase {
                if currentRound < beginnerUpperFretBoundary {
                    currentRound += 1
                } else {
                    startGameFromBeginning()
                    return
                }
            } else {
                if currentRound > beginnerLowerFretBoundary {
                    currentRound -= 1
                } else {
                    startGameFromBeginning()
                    return
                }
            }
        }
    }
    
        
    private func prepareCurrentQuestion() {
    if playLessonStyle == "random" {
        // Random style: use note sequence from generator
        let idx = randomNoteGenerator.sequenceProgressIndex
        guard idx < randomNoteGenerator.currentNoteSequence.count,
              let nextString = randomNoteGenerator.expectedString else { return }
        let correctNote = randomNoteGenerator.currentNoteSequence[idx]
        let useFlats = layoutMode == .beginner ? beginnerUsesFlats : false
        let incorrectNote = randomIncorrectNote(excluding: correctNote, useFlats: useFlats)
        let correctOnLeft = Bool.random()
        if correctOnLeft {
            leftChoiceNote = correctNote
            rightChoiceNote = incorrectNote
        } else {
            leftChoiceNote = incorrectNote
            rightChoiceNote = correctNote
        }
        currentPromptStrings = [nextString]
        lastPromptedCorrectNote = correctNote
        lastPromptedStringHalf = .left
        lastPromptedStringNumber = nextString
        withAnimation(.easeInOut(duration: 1.3)) {
            currentFretStart = max(currentRound, 0)
        }
    } else if playLessonStyle == "sequential" {
        // Sequential style: use SequentialNoteGenerator
        let idx = sequentialNoteGenerator.sequenceProgressIndex
        guard idx < sequentialNoteGenerator.currentNoteSequence.count,
              let nextString = sequentialNoteGenerator.expectedString else { return }
        let correctNote = sequentialNoteGenerator.currentNoteSequence[idx]
        let useFlats = layoutMode == .beginner ? beginnerUsesFlats : false
        let incorrectNote = randomIncorrectNote(excluding: correctNote, useFlats: useFlats)
        let correctOnLeft = Bool.random()
        if correctOnLeft {
            leftChoiceNote = correctNote
            rightChoiceNote = incorrectNote
        } else {
            leftChoiceNote = incorrectNote
            rightChoiceNote = correctNote
        }
        correctAnswerSide = correctOnLeft ? .left : .right
        currentPromptStrings = [nextString]
        lastPromptedCorrectNote = correctNote
        lastPromptedStringHalf = .left
        lastPromptedStringNumber = nextString
        withAnimation(.easeInOut(duration: 1.3)) {
            currentFretStart = max(currentRound, 0)
        }
    } else {
        // Chord style: existing behavior
        let fret = max(currentRound, 0)
        let useFlats = layoutMode == .beginner ? beginnerUsesFlats : false
        let targetString = activeStringOrder.isEmpty ? 1 : activeStringOrder.randomElement() ?? 1
        let correctNote = noteName(forString: targetString, fret: fret, useFlats: useFlats)
        let incorrectNote = randomIncorrectNote(excluding: correctNote, useFlats: useFlats)
        let correctOnLeft = Bool.random()

        if correctOnLeft {
            leftChoiceNote = correctNote
            rightChoiceNote = incorrectNote
        } else {
            leftChoiceNote = incorrectNote
            rightChoiceNote = correctNote
        }

        currentPromptStrings = [targetString]
        lastPromptedCorrectNote = correctNote
        withAnimation(.easeInOut(duration: 1.3)) {
            currentFretStart = fret
        }
    }
}

    private func payoutForRound(_ round: Int) -> Int {
        _ = round
        return 5
    }

    private func animateBankResetToZero(completion: @escaping () -> Void) {
        let startValue = displayedBankDollars
        guard startValue > 0 else {
            bankDollars = 0
            displayedBankDollars = 0
            walletDollars = 0
            completion()
            return
        }
        let steps = 24
        let interval: Double = 0.018
        for step in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + (Double(step) * interval)) {
                let remainingRatio = max(0, 1.0 - (Double(step) / Double(steps)))
                displayedBankDollars = Int((Double(startValue) * remainingRatio).rounded())
                if step == steps {
                    bankDollars = 0
                    displayedBankDollars = 0
                    walletDollars = 0
                    completion()
                }
            }
        }
    }

    private func noteName(forString string: Int, fret: Int, useFlats: Bool) -> String {
        guard let openNote = openNoteByString[string],
              let openIndex = chromaticSharps.firstIndex(of: openNote) else {
            return "?"
        }
        let noteIndex = (openIndex + fret) % chromaticSharps.count
        let scale = useFlats ? chromaticFlats : chromaticSharps
        return scale[noteIndex]
    }

    private func randomIncorrectNote(excluding correct: String, useFlats: Bool) -> String {
        let source = useFlats ? chromaticFlats : chromaticSharps
        let pool = source.filter { $0 != correct }
        return pool.randomElement() ?? "C"
    }

    private func textWidth(for text: String, font: UIFont) -> CGFloat {
        let attributes = [NSAttributedString.Key.font: font]
        return ceil(text.size(withAttributes: attributes).width)
    }

    private func handleGameplayMenuSelection(_ option: GameplayMenuOption) {
        gameplayMenuExpanded = false
        if option == .audio {
            availableBackingTracks = BackingTrack.discoverBundledTracks()
            audioSettings.selectInitialBackingTrackIfNeeded(from: availableBackingTracks)
            showAudioPage = true
            showDeveloperPrompt("MENU: AUDIO")
            return
        }
        onMenuSelection?(option)
        showDeveloperPrompt("MENU: \(option.title)")
    }

    private func handleHintButtonPress() {
        postponeBeatDeadlineForAssist()
        if layoutMode == .beginner {
            showFretboardGuide.toggle()
        }
        showDeveloperPrompt("HINT: \(currentCorrectNote)")
    }

    private func handleStartupSpeech(for phase: StartupSequenceView.Phase) {
        guard audioEngineEnabled else { return }
        switch phase {
        case .systemOnline:
            if startupSpeechPhase == .pendingSystem {
                gameplayAudioEngine.speakStartupAlert("SYSTEM ONLINE", volume: stringVolume)
                startupSpeechPhase = .pendingPhase
            }
        case .phaseOne:
            if startupSpeechPhase == .pendingPhase {
                gameplayAudioEngine.speakStartupAlert("PHASE ONE", volume: stringVolume)
                startupSpeechPhase = .pendingArmed
            }
        case .armed:
            if startupSpeechPhase == .pendingArmed {
                gameplayAudioEngine.speakStartupAlert(layoutMode == .beginner ? beginnerStartupArmedText : "MEMORIZATION SEQUENCE ARMED", volume: stringVolume)
                startupSpeechPhase = .idle
            }
        }
    }

    private func handleBeginnerConsoleButtonPress(selectedNote: String, selectedString: Int, buttonIndex: Int) {
        guard layoutMode == .beginner else { return }
        if isRoundArmed {
            handleRoundStartButton()
            return
        }
        if isCodeScreensaverMode {
            submitAnswer(.left)
            return
        }

        let canAdvanceBeginnerProgression = !isResolvingAnswer
            && !beginnerRuntime.pendingRewardStageAdvance
            && !beginnerRuntime.roundOneIntroActive

        activePickedStringNumbers = [selectedString]
        beginnerRuntime.rewardNoteTextByString = nil
        beginnerRuntime.lastPickedNote = selectedNote
        beginnerRuntime.answerBoxReady = true
        activeAnswerFeedback = nil
        questionBoxAssistActive = false

        guard canAdvanceBeginnerProgression else {
            playGuitarNote(forString: selectedString, fret: max(currentRound, 0), velocity: 0.98)
            return
        }

        handleBeginnerRoundOneProgressionIfNeeded(selectedNote: selectedNote, selectedString: selectedString, buttonIndex: buttonIndex)

        playGuitarNote(forString: selectedString, fret: max(currentRound, 0), velocity: 0.98)
    }

    private func handleBeginnerRoundOneProgressionIfNeeded(selectedNote: String, selectedString: Int, buttonIndex: Int) {
        // Random style: check against random note sequence
        if playLessonStyle == "random" {
            guard beginnerRuntime.currentPhaseNumber >= 1 && beginnerRuntime.currentPhaseNumber <= 8 else { return }
            guard !randomNoteGenerator.currentNoteSequence.isEmpty else { return }
            guard !randomNoteGenerator.isSequenceComplete() else { return }

            // Validate: note must match AND must not reuse an already-played string for that note
            guard randomNoteGenerator.isValidAnswer(note: selectedNote, string: selectedString) else { return }

            // Correct answer - light up the button
            beginnerPressedButtonIndex = buttonIndex
            beginnerPressedButtonCorrect = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                beginnerPressedButtonIndex = nil
                beginnerPressedButtonCorrect = false
            }
            randomNoteGenerator.advanceSequence()

            if randomNoteGenerator.isSequenceComplete() {
                if beginnerRuntime.scaleRepetitionsRemaining <= 1 {
                    if beginnerRuntime.pendingRoundShiftBeatPosition == nil {
                        beginnerRuntime.pendingRoundShiftBeatPosition = roundRevealElapsedBeats + 2.0
                    }
                } else {
                    beginnerRuntime.scaleRepetitionsRemaining -= 1
                    randomNoteGenerator.resetForNewFret()
                    beginnerRuntime.randomRevealCount = 0
                    beginnerRuntime.randomRevealStartBeatBucket = nil
                    beginnerRuntime.answerBoxReady = false
                    let useFlats = layoutMode == .beginner ? beginnerUsesFlats : false
                    randomNoteGenerator.generateNoteSequence(for: max(currentRound, 0), useFlats: useFlats)
                }
            }
            return
        }

        // Sequential style: check against sequential note sequence
        if playLessonStyle == "sequential" {
            guard beginnerRuntime.currentPhaseNumber >= 1 && beginnerRuntime.currentPhaseNumber <= 8 else { return }
            guard !sequentialNoteGenerator.currentNoteSequence.isEmpty else { return }
            guard !sequentialNoteGenerator.isSequenceComplete() else { return }

            // Validate: note must match AND must not reuse an already-played string for that note
            guard sequentialNoteGenerator.isValidAnswer(note: selectedNote, string: selectedString) else { return }

            // Correct answer - light up the button
            beginnerPressedButtonIndex = buttonIndex
            beginnerPressedButtonCorrect = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                beginnerPressedButtonIndex = nil
                beginnerPressedButtonCorrect = false
            }
            sequentialNoteGenerator.advanceSequence()

            if sequentialNoteGenerator.isSequenceComplete() {
                if beginnerRuntime.scaleRepetitionsRemaining <= 1 {
                    if beginnerRuntime.pendingRoundShiftBeatPosition == nil {
                        beginnerRuntime.pendingRoundShiftBeatPosition = roundRevealElapsedBeats + 2.0
                    }
                } else {
                    beginnerRuntime.scaleRepetitionsRemaining -= 1
                    sequentialNoteGenerator.resetForNewFret()
                    beginnerRuntime.sequentialRevealCount = 0
                    beginnerRuntime.sequentialRevealStartBeatBucket = nil
                    beginnerRuntime.answerBoxReady = false
                    let useFlats = layoutMode == .beginner ? beginnerUsesFlats : false
                    sequentialNoteGenerator.generateNoteSequence(for: max(currentRound, 0), useFlats: useFlats, lowToHigh: beginnerRuntime.currentPhaseNumber <= 2)
                    prepareCurrentQuestion()
                }
            }
            return
        }

        // Chord style: existing behavior
        // Chord mode active in phases 5-6
        guard playLessonStyle == "chord",
              beginnerRuntime.pentatonicRevealCount >= beginnerCurrentScaleNotes.count
        else { return }

        let currentScaleNotes = beginnerCurrentScaleNotes
        guard !currentScaleNotes.isEmpty else { return }

        let safeSequenceIndex = min(max(beginnerRuntime.scaleSequenceIndex, 0), currentScaleNotes.count - 1)
        if safeSequenceIndex != beginnerRuntime.scaleSequenceIndex {
            beginnerRuntime.scaleSequenceIndex = safeSequenceIndex
        }

        let expectedNote = currentScaleNotes[safeSequenceIndex]
        if selectedNote == expectedNote {
            // Correct answer - light up the button
            beginnerPressedButtonIndex = buttonIndex
            beginnerPressedButtonCorrect = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                beginnerPressedButtonIndex = nil
                beginnerPressedButtonCorrect = false
            }
            if safeSequenceIndex == currentScaleNotes.count - 1 {
                if beginnerRuntime.scaleRepetitionsRemaining <= 1 {
                    if let rewardPolicy = beginnerRewardPolicyForCurrentStage() {
                        playGuitarNote(forString: selectedString, fret: max(currentRound, 0), velocity: 0.98)
                        scheduleBeginnerRewardChordThenAdvance(selectedString: selectedString, policy: rewardPolicy)
                    } else {
                        playGuitarNote(forString: selectedString, fret: max(currentRound, 0), velocity: 0.98)
                        scheduleBeginnerAdvanceAfterFinalNoteHold(selectedString: selectedString)
                    }
                    return
                }

                beginnerRuntime.scaleRepetitionsRemaining -= 1
                beginnerRuntime.scaleSequenceIndex = 0
            } else {
                beginnerRuntime.scaleSequenceIndex += 1
            }
        } else {
            // Incorrect answer - light up button red
            beginnerPressedButtonIndex = buttonIndex
            beginnerPressedButtonCorrect = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                beginnerPressedButtonIndex = nil
                beginnerPressedButtonCorrect = false
            }
            beginnerRuntime.scaleSequenceIndex = (selectedNote == currentScaleNotes[0]) ? 1 : 0
        }
    }

    private func playCurrentPromptedGuitarNotes(velocity: Float) {
        let fret = max(currentRound, 0)
        let promptStrings = currentPromptStrings.isEmpty ? [1] : currentPromptStrings
        for (index, stringNumber) in promptStrings.enumerated() {
            let delay = Double(index) * 0.035
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                playGuitarNote(forString: stringNumber, fret: fret, velocity: velocity)
            }
        }
    }

    private func playGuitarNote(forString stringNumber: Int, fret: Int, velocity: Float) {
        guitarNoteEngine.play(string: stringNumber, fret: max(fret, 0), velocity: velocity)
    }

    private func syncBackingTrackPlayback(allowResumeFromPause: Bool = false) {
        guard !availableBackingTracks.isEmpty else {
            midiEngine.stop()
            isBackingTrackPlaying = false
            return
        }

        audioSettings.selectInitialBackingTrackIfNeeded(from: availableBackingTracks)
        guard backingTrackShouldBeActive else {
            midiEngine.stop()
            isBackingTrackPlaying = false
            return
        }

        guard !transportStoppedForResume else {
            isBackingTrackPlaying = false
            return
        }

        guard let selectedTrackID = audioSettings.selectedBackingTrackID,
              let selectedTrack = availableBackingTracks.first(where: { $0.id == selectedTrackID }),
              let trackURL = selectedTrack.resourceURL() else {
            midiEngine.stop()
            isBackingTrackPlaying = false
            return
        }

        applyBeginnerBassTransposeForCurrentStage()
        
        // If allowed and same track was paused, resume from that position
        if allowResumeFromPause {
            midiEngine.resume()
            isBackingTrackPlaying = midiEngine.isPlaying
            return
        }

        // Skip restart if the same URL is already playing — avoids mid-beat click
        if midiEngine.isPlaying, midiEngine.activeURL == trackURL {
            isBackingTrackPlaying = true
            return
        }

        midiEngine.play(url: trackURL, title: selectedTrack.title, loop: true)
        isBackingTrackPlaying = midiEngine.isPlaying
    }

    private func handleFretboardButtonPress() {
        showFretboardGuide.toggle()
        postponeBeatDeadlineForAssist()
        showDeveloperPrompt(showFretboardGuide ? "Fretboard guide ON" : "Fretboard guide OFF")
    }

    private func handleRoundStartButton(animateNeckSlideFromStartup: Bool = false) {
        if isCodeScreensaverMode {
            guard !isLaunchTransitionAnimating else { return }
            isLaunchTransitionAnimating = true
            startupNeckVisualsHidden = true
            launchTileScale = 1
            launchTileOpacity = 1
            withAnimation(.easeIn(duration: 0.4725)) {
                launchTileScale = 0.1
                launchTileOpacity = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4725) {
                isCodeScreensaverMode = false
                startupSequenceActivated = false
                startupSequenceElapsed = 0
                startupSpeechPhase = .idle
                isLaunchTransitionAnimating = false
                launchTileScale = 1
                launchTileOpacity = 1
                questionBoxIntroProgress = 1
                handleRoundStartButton(animateNeckSlideFromStartup: true)
            }
            return
        }

        if layoutMode == .beginner {
            beginnerRuntime.coursePhase = .round1Ascending
        }
        isCodeScreensaverMode = false
        startupSequenceActivated = false
        startupSequenceElapsed = 0
        startupSpeechPhase = .idle
        questionBoxIntroProgress = 1
        isRoundPaused = false
        transportStoppedForResume = false
        isRoundArmed = false
        roundRevealElapsedBeats = 0
        roundRevealLastTickDate = nil

        // Ensure reveal beat-buckets are always fresh for the active style at START
        if playLessonStyle == "random" {
            beginnerRuntime.randomRevealCount = 0
            beginnerRuntime.randomRevealStartBeatBucket = nil
        } else if playLessonStyle == "sequential" {
            beginnerRuntime.sequentialRevealCount = 0
            beginnerRuntime.sequentialRevealStartBeatBucket = nil
        }

        // Trigger phase announcement for sequential mode only
        if layoutMode == .beginner && playLessonStyle == "sequential" {
            beginnerRuntime.phaseAnnouncementStartBeat = 0
            beginnerRuntime.phaseAnnouncementPhase = 1
            beginnerRuntime.sequentialRevealCount = 0
            beginnerRuntime.sequentialRevealStartBeatBucket = nil
        }
        
        // Reset reveal counts for random mode to ensure progressive reveal
        if layoutMode == .beginner && playLessonStyle == "random" {
            beginnerRuntime.randomRevealCount = 0
            beginnerRuntime.randomRevealStartBeatBucket = nil
        }

        startGameFromBeginning(animateNeckSlideFromStartup: animateNeckSlideFromStartup)
        updateDirectionLockState()
        if !animateNeckSlideFromStartup {
            syncBackingTrackPlayback()
        }
    }

    private func handleStartButtonPress() {
        // Stage 1: Phase completed message showing → fast-path: skip wait, go straight to next phase armed state
        if layoutMode == .beginner, beginnerRuntime.phaseCompletedMessagePending {
            beginnerRuntime.pendingPhaseCompletedAutoAdvanceDate = nil
            beginnerRuntime.phaseCompletedMessagePending = false
            beginnerRuntime.phaseCompletedMessageStartBeat = nil
            advanceToNextPhaseArmedState()
            return
        }

        // Stage 2: Phase announcement done → enter armed/screensaver state for new phase
        if layoutMode == .beginner, beginnerRuntime.phaseAnnouncementStartBeat != nil {
            beginnerRuntime.phaseAnnouncementStartBeat = nil
            beginnerRuntime.phaseAnnouncementPhase = 0
            isRoundArmed = true
            isCodeScreensaverMode = true
            startupSequenceActivated = false
            startupSequenceElapsed = 0
            startupSpeechPhase = .idle
            isRoundPaused = false
            transportStoppedForResume = false
            roundRevealElapsedBeats = 0
            roundRevealLastTickDate = nil
            prepareCurrentQuestion()
            syncBackingTrackPlayback()
            return
        }

        if startupStartButtonAttentionActive,
           layoutMode == .beginner,
           isCodeScreensaverMode,
           !startupSequenceActivated {
            startupSequenceActivated = true
            startupSequenceStartDate = .now
            startupSequenceElapsed = 0
            startupSpeechPhase = .pendingArmed
            questionBoxIntroProgress = 0
            return
        }

        if transportStoppedForResume {
            resumeRoundFromTransportStop()
            return
        }

        if isRoundPaused {
            resumeRoundFromTransportStop(forceIfPaused: true)
            return
        }

        if !isRoundArmed {
            return
        }

        handleRoundStartButton()
    }

    private func handleRoundStopButton() {
        guard canPressStopButton else { return }

        isRoundPaused = true
        transportStoppedForResume = true
        roundRevealLastTickDate = nil
        midiEngine.pause()
        isBackingTrackPlaying = midiEngine.isPlaying
        beginnerRuntime.beatLightFlashOn = false
        beginnerRuntime.beatLightLastProcessedBeat = nil
        beginnerRuntime.beatLightIntroMeasureSkipped = false
        updateDirectionLockState()
    }

    private func resumeRoundFromTransportStop(forceIfPaused: Bool = false) {
        guard transportStoppedForResume || (forceIfPaused && isRoundPaused) else { return }

        transportStoppedForResume = false
        isRoundPaused = false
        roundRevealLastTickDate = nil
        midiEngine.resume()
        beginnerRuntime.beatLightFlashOn = false
        beginnerRuntime.beatLightLastProcessedBeat = nil
        beginnerRuntime.beatLightIntroMeasureSkipped = false
        updateDirectionLockState()
    }

    private func handleRoundResetButton() {
        guard canPressResetButton else { return }

        if layoutMode == .beginner {
            beginnerRuntime.coursePhase = .round1Ascending
            beginnerRuntime.currentPhaseNumber = 1
            beginnerRuntime.currentRoundInPhase = 1
            beginnerRuntime.correctAnswersAtCurrentFret = 0
        }
        isCodeScreensaverMode = true
        startupSequenceActivated = true
        startupSequenceStartDate = .now
        startupSequenceElapsed = 0
        startupSpeechPhase = .pendingArmed
        questionBoxIntroProgress = 0
        isLaunchTransitionAnimating = false
        launchTileScale = 1
        launchTileOpacity = 1
        isRoundPaused = false
        transportStoppedForResume = false
        isRoundArmed = true
        roundRevealElapsedBeats = 0
        roundRevealLastTickDate = nil
        syncBackingTrackPlayback()
        startGameFromBeginning()
        developerPromptText = ""
        beginnerRuntime.answerBoxReady = false
        updateDirectionLockState()
    }

    private func postponeBeatDeadlineForAssist() {
        guard !isCodeScreensaverMode, modeVariant == .beat else { return }
        let bpm = Double(max(beatBPM, 60))
        beatQuestionDeadline = .now.addingTimeInterval(max(1.0, 120.0 / bpm))
    }

    private func showDeveloperPrompt(_ text: String) {
        developerPromptText = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            if developerPromptText == text {
                developerPromptText = ""
            }
        }
    }

    private func beginBeginnerRoundOneCelebration() {
        guard layoutMode == .beginner else { return }
        beginnerRuntime.coursePhase = .round1Celebration
        developerPromptText = ""
        activeAnswerFeedback = nil
        questionBoxAssistActive = false
        beginnerRuntime.autoPlayNextDate = nil
        beginnerRuntime.celebrationFlashOn = true
        beginnerRuntime.celebrationNextFlashDate = .now.addingTimeInterval(0.32)
    }

    private func beginBeginnerRoundTwoCelebration() {
        guard layoutMode == .beginner else { return }
        beginnerRuntime.coursePhase = .round2Celebration
        developerPromptText = ""
        activeAnswerFeedback = nil
        questionBoxAssistActive = false
        beginnerRuntime.autoPlayNextDate = nil
        beginnerRuntime.celebrationFlashOn = true
        beginnerRuntime.celebrationNextFlashDate = .now.addingTimeInterval(0.32)
    }

    private func armBeginnerRoundTwo() {
        guard layoutMode == .beginner else { return }
        beginnerRuntime.coursePhase = .round2Arming
        developerPromptText = ""
        activeAnswerFeedback = nil
        questionBoxAssistActive = false
        beginnerRuntime.autoPlayNextDate = nil
        beginnerRuntime.roundOneIntroActive = false
        beginnerRuntime.roundOneSequenceStartDate = nil
        beginnerRuntime.revealStartBeatBucket = nil
        beginnerRuntime.introStartBeatBucket = nil
        beginnerRuntime.pentatonicRevealCount = 0
        beginnerRuntime.answerBoxReady = false
        beginnerRuntime.lastPickedNote = nil
        activePickedStringNumbers = []
        beginnerRuntime.celebrationFlashOn = true
        beginnerRuntime.celebrationNextFlashDate = .now.addingTimeInterval(0.32)
    }

    private func beginBeginnerRoundTwo() {
        guard layoutMode == .beginner else { return }
        beginnerRuntime.coursePhase = .round2Descending
        isDescendingPhase = beginnerRoundTwoStartsDescending
        currentRound = beginnerRoundTwoStartingFret
        roundStringIndex = 0
        streakMeterLitColumns = 0
        streakMeterFailureActive = false
        streakMeterFailureVisibleColumns = 0
        beginnerRuntime.correctAnswersAtCurrentFret = 0
        beginnerRuntime.scaleRepetitionsRemaining = effectivePlayRepetitions
        lastPromptedCorrectNote = nil
        lastPromptedStringHalf = nil
        lastPromptedStringNumber = nil
        recentPromptedCorrectNotes = []
        activeAnswerFeedback = nil
        currentCorrectNote = ""
        beginnerRuntime.celebrationFlashOn = false
        beginnerRuntime.celebrationNextFlashDate = nil
        prepareCurrentQuestion()
    }

    private func handlePhaseCompletion() {
        guard layoutMode == .beginner else { return }

        // Check if this is the final phase (phase 8)
        if beginnerRuntime.currentPhaseNumber >= 8 {
            // Show final celebration
            beginBeginnerRoundOneCelebration()
            return
        }

        // Stage 1: Show "Phase N Completed" message
        // Do NOT increment phase number yet
        // Do NOT reset fret position yet

        // Set up phase completed message
        beginnerRuntime.completedPhaseNumber = beginnerRuntime.currentPhaseNumber
        beginnerRuntime.phaseCompletedMessagePending = true
        beginnerRuntime.phaseCompletedMessageStartBeat = roundRevealElapsedBeats

        // Schedule MIDI stop in 3 beats (wall-clock so it fires even while armed)
        let secondsPer3Beats = 3.0 * 60.0 / Double(max(beatBPM, 60))
        beginnerRuntime.pendingMidiStopDate = Date().addingTimeInterval(secondsPer3Beats)

        // Auto-advance to armed/screensaver state after 4 beats (3 music + 1 message display)
        let secondsPer4Beats = 4.0 * 60.0 / Double(max(beatBPM, 60))
        beginnerRuntime.pendingPhaseCompletedAutoAdvanceDate = Date().addingTimeInterval(secondsPer4Beats)

        // Clear answer state
        beginnerRuntime.lastPickedNote = nil
        beginnerRuntime.rewardNoteTextByString = nil
        beginnerRuntime.answerBoxReady = false
        activeAnswerFeedback = nil
        questionBoxAssistActive = false
        beginnerRuntime.autoPlayNextDate = nil

        // Enter armed state - will wait for START button after completed message
        isRoundArmed = true
    }

    private func advanceToNextPhaseArmedState() {
        guard layoutMode == .beginner else { return }

        // Increment phase number
        let nextPhase = beginnerRuntime.currentPhaseNumber + 1
        beginnerRuntime.currentPhaseNumber = nextPhase
        beginnerRuntime.currentRoundInPhase = 1

        // Set starting fret for the new phase
        let nextPhaseIsDescending = [2, 4, 6, 8].contains(nextPhase)
        currentRound = nextPhaseIsDescending ? 12 : 0

        // Reset counters
        roundStringIndex = 0
        beginnerRuntime.correctAnswersAtCurrentFret = 0
        beginnerRuntime.scaleRepetitionsRemaining = effectivePlayRepetitions

        // Reset reveal state for the active style
        if playLessonStyle == "random" {
            randomNoteGenerator.generateNoteSequence(for: currentRound, useFlats: beginnerUsesFlats)
            beginnerRuntime.randomRevealCount = 0
            beginnerRuntime.randomRevealStartBeatBucket = nil
        } else if playLessonStyle == "sequential" {
            let lowToHigh = nextPhase <= 2
            sequentialNoteGenerator.generateNoteSequence(for: currentRound, useFlats: beginnerUsesFlats, lowToHigh: lowToHigh)
            beginnerRuntime.sequentialRevealCount = 0
            beginnerRuntime.sequentialRevealStartBeatBucket = nil
        }

        applyBeginnerBassTransposeForCurrentStage()
        prepareCurrentQuestion()

        // Enter screensaver with startup sequence already active (green armed state)
        roundRevealElapsedBeats = 0
        roundRevealLastTickDate = nil
        isRoundArmed = true
        isCodeScreensaverMode = true
        startupSequenceActivated = true
        startupSequenceStartDate = .now
        startupSequenceElapsed = 0
        startupSpeechPhase = .pendingArmed
        questionBoxIntroProgress = 0
        syncBackingTrackPlayback()
    }

    private func beginNextPhaseFromTransition() {
        guard layoutMode == .beginner, beginnerRuntime.phaseTransitionPending else { return }

        // Clear transition state
        beginnerRuntime.phaseTransitionPending = false

        // Reset gameplay state for new phase
        beginnerRuntime.roundOneIntroActive = true
        beginnerRuntime.roundOneSequenceStartDate = Date()
        roundRevealElapsedBeats = 0
        roundRevealLastTickDate = nil

        // Prepare first question
        prepareCurrentQuestion()
    }

    // MARK: - Private Helper Methods
    
    private func midiNoteValue(forNote note: String) -> Int? {
        let noteToMIDI: [String: Int] = [
            "C": 60, "C#": 61, "Db": 61,
            "D": 62, "D#": 63, "Eb": 63,
            "E": 64,
            "F": 65, "F#": 66, "Gb": 66,
            "G": 67, "G#": 68, "Ab": 68,
            "A": 69, "A#": 70, "Bb": 70,
            "B": 71
        ]
        return noteToMIDI[note]
    }
}

private struct PurpleGuidelineLayer: View {
    let size: CGSize
    let positions: [CGFloat]

    var body: some View {
        ZStack {
            ForEach(Array(positions.enumerated()), id: \.offset) { _, y in
                Rectangle()
                    .fill(Color.purple.opacity(0.9))
                    .frame(width: size.width, height: 2)
                    .position(x: size.width / 2, y: y)
            }
        }
        .frame(width: size.width, height: size.height)
        .allowsHitTesting(false)
    }
}

private extension BeginnerGameplayView {
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

private struct NutFirstFretHighlight: View {
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .strokeBorder(Color.red.opacity(0.9), lineWidth: max(width * 0.004, 2))
            .shadow(color: Color.red.opacity(0.25), radius: 8, x: 0, y: 4)
            .frame(width: width, height: height)
            .allowsHitTesting(false)
    }
}

private struct DarkMatteOverlay: View {
    let canvasSize: CGSize
    let highlightWidth: CGFloat
    let highlightHeight: CGFloat
    let highlightCenter: CGPoint
    let highlightCornerRadius: CGFloat

    var body: some View {
        ZStack {
            Color.black.opacity(0.82)
                .frame(width: canvasSize.width, height: canvasSize.height)

            RoundedRectangle(cornerRadius: highlightCornerRadius, style: .continuous)
                .fill(Color.black)
                .frame(width: highlightWidth, height: highlightHeight)
                .position(x: highlightCenter.x, y: highlightCenter.y)
                .blendMode(.destinationOut)
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .compositingGroup()
        .allowsHitTesting(false)
    }
}

private struct BindingLayer: View {
    var body: some View {
        GeometryReader { geo in
            let stripWidth = max(geo.size.width * 0.02, 6)

            ZStack(alignment: .top) {
                HStack {
                    bindingStrip(width: stripWidth, height: geo.size.height)
                    Spacer()
                    bindingStrip(width: stripWidth, height: geo.size.height)
                }
                
                Rectangle()
                    .fill(Color(red: 0.65, green: 0.62, blue: 0.58))
                    .frame(width: geo.size.width - stripWidth * 2, height: 1)
                    .position(x: geo.size.width / 2, y: 0.5)
            }
        }
        .allowsHitTesting(false)
    }

    private func bindingStrip(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: width / 2)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.97, green: 0.95, blue: 0.88),
                        Color(red: 0.91, green: 0.87, blue: 0.78)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                VStack {
                    Color.white.opacity(0.35)
                        .frame(height: 1)
                    Spacer()
                }
            )
            .frame(width: width, height: height)
            .shadow(color: Color.black.opacity(0.25), radius: 4, x: 1, y: 0)
    }
}

private struct FretWireLayer: View {
    let fretRatios: [CGFloat]

    var body: some View {
        GeometryReader { geo in
            let height = geo.size.height
            let width = geo.size.width * 1.04
            let wireThickness = max(geo.size.height * 0.0018, 2)
            ZStack(alignment: .topLeading) {
                ForEach(1..<fretRatios.count, id: \.self) { index in
                    let ratio = fretRatios[index]
                    RoundedRectangle(cornerRadius: wireThickness / 2, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.96, green: 0.96, blue: 0.94),
                                    Color(red: 0.7, green: 0.72, blue: 0.75),
                                    Color(red: 0.45, green: 0.47, blue: 0.5),
                                    Color(red: 0.98, green: 0.98, blue: 0.99)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: wireThickness / 2)
                                .stroke(Color.black.opacity(0.3), lineWidth: 0.35)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: wireThickness / 2)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.8), .clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 0.7
                                )
                        )
                        .shadow(color: Color.black.opacity(0.35), radius: 2, x: 0, y: 1)
                        .frame(width: width, height: wireThickness)
                        .offset(
                            x: -(width - geo.size.width) / 2,
                            y: ratio * height - wireThickness / 2
                        )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct FretMarkerLayer: View {
    let fretRatios: [CGFloat]

    private let markedFrets: [Int] = [3, 5, 7, 9, 15, 17, 19, 21]
    private let stratNutWidthInches: CGFloat = 1.650
    private let stratStringSpanInches: CGFloat = 1.362
    private let totalStrings: Int = 6

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let markerDiameter = max(min(width, height) * 0.135, 36)
            let widthPerInch = width / stratNutWidthInches
            let interStringSpacing = (stratStringSpanInches / CGFloat(totalStrings - 1)) * widthPerInch
            let edgeMargin = ((stratNutWidthInches - stratStringSpanInches) / 2) * widthPerInch
            // String indices from low-E side: string6=0, string5=1, string4=2, string3=3, string2=4, string1=5
            let string2X = edgeMargin + 4 * interStringSpacing
            let string5X = edgeMargin + 1 * interStringSpacing

            ZStack {
                ForEach(markedFrets, id: \.self) { fret in
                    if fretRatios.indices.contains(fret), fretRatios.indices.contains(fret - 1) {
                        let start = fretRatios[fret - 1]
                        let end = fretRatios[fret]
                        let yPosition = ((start + end) / 2) * height

                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.white.opacity(0.98),
                                        Color(red: 0.93, green: 0.93, blue: 0.9),
                                        Color(red: 0.72, green: 0.72, blue: 0.7)
                                    ],
                                    center: .center,
                                    startRadius: markerDiameter * 0.05,
                                    endRadius: markerDiameter * 0.6
                                )
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.black.opacity(0.18), lineWidth: 1)
                            )
                            .frame(width: markerDiameter, height: markerDiameter)
                            .position(x: width / 2, y: yPosition)
                            .shadow(color: Color.black.opacity(0.18), radius: 2, x: 0, y: 1)
                    }
                }

                // 12th fret double dots at string 2 (B) and string 5 (A)
                if fretRatios.indices.contains(12), fretRatios.indices.contains(11) {
                    let y12 = ((fretRatios[11] + fretRatios[12]) / 2) * height
                    let dotFill = RadialGradient(
                        colors: [
                            Color.white.opacity(0.98),
                            Color(red: 0.93, green: 0.93, blue: 0.9),
                            Color(red: 0.72, green: 0.72, blue: 0.7)
                        ],
                        center: .center,
                        startRadius: markerDiameter * 0.05,
                        endRadius: markerDiameter * 0.6
                    )
                    Circle()
                        .fill(dotFill)
                        .overlay(Circle().stroke(Color.black.opacity(0.18), lineWidth: 1))
                        .frame(width: markerDiameter, height: markerDiameter)
                        .position(x: string2X, y: y12)
                        .shadow(color: Color.black.opacity(0.18), radius: 2, x: 0, y: 1)
                    Circle()
                        .fill(dotFill)
                        .overlay(Circle().stroke(Color.black.opacity(0.18), lineWidth: 1))
                        .frame(width: markerDiameter, height: markerDiameter)
                        .position(x: string5X, y: y12)
                        .shadow(color: Color.black.opacity(0.18), radius: 2, x: 0, y: 1)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct NutLayer: View {
    let width: CGFloat
    let height: CGFloat

    private let stratNutWidthInches: CGFloat = 1.650
    private let stratStringSpanInches: CGFloat = 1.362
    private let totalStrings: Int = 6

    var body: some View {
        GeometryReader { geo in
            let nutHeight = geo.size.height
            let bevelHeight = nutHeight * 0.25
            let widthPerInch = geo.size.width / stratNutWidthInches
            let interStringSpacing = (stratStringSpanInches / CGFloat(totalStrings - 1)) * widthPerInch
            let edgeMargin = ((stratNutWidthInches - stratStringSpanInches) / 2) * widthPerInch
            let grooveCenters = (0..<totalStrings).map { index in
                edgeMargin + CGFloat(index) * interStringSpacing
            }

            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.96, green: 0.94, blue: 0.88),
                                Color(red: 0.90, green: 0.86, blue: 0.78)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 1)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                    )
                    .frame(height: nutHeight + bevelHeight)

                Rectangle()
                    .fill(Color.white.opacity(0.45))
                    .frame(width: geo.size.width * 0.98, height: bevelHeight)
                    .offset(y: nutHeight * 0.15)
                    .mask(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.4)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                let grooveWidth = max(1, geo.size.width * 0.01)
                let grooveHeight = bevelHeight * 1.4
                ForEach(0..<totalStrings, id: \.self) { index in
                    Rectangle()
                        .fill(Color.black.opacity(0.35))
                        .frame(width: grooveWidth, height: grooveHeight)
                        .cornerRadius(grooveWidth / 2)
                        .offset(
                            x: grooveCenters[index] - geo.size.width / 2,
                            y: nutHeight * 0.1
                        )
                }

                Rectangle()
                    .fill(Color.black.opacity(0.25))
                    .frame(width: 1, height: nutHeight + bevelHeight * 0.6)
                    .offset(y: nutHeight * 0.2)
            }
        }
        .frame(width: width, height: height)
        .padding(.bottom, height * 0.05)
        .allowsHitTesting(false)
    }
}

private struct RosewoodSegmentedBackground: View {
    let fretRatios: [CGFloat]
    let cornerRadius: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let neckHeight = geometry.size.height
            let neckWidth = geometry.size.width
            let segments = segmentBounds(from: fretRatios)
            let bindingInset = max(neckWidth * 0.02, 6)
            let rosewoodTexture = Image("RosewoodOne")

            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    let groupSize = 3
                    ForEach(Array(stride(from: 0, to: segments.count, by: groupSize)), id: \.self) { start in
                        let end = min(start + groupSize, segments.count)
                        let groupHeight = (start..<end).reduce(CGFloat(0)) { acc, idx in
                            acc + max((segments[idx].end - segments[idx].start) * neckHeight, 1)
                        }
                        rosewoodTexture
                            .resizable()
                            .scaledToFill()
                            .frame(width: neckWidth, height: groupHeight)
                            .clipped()
                    }
                }
                .padding(.horizontal, bindingInset)

                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.black.opacity(0.1), lineWidth: 1)

                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.14),
                                Color.clear,
                                Color.black.opacity(0.18)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .blendMode(.multiply)

                VStack(spacing: 0) {
                    ForEach(Array(segments.enumerated()), id: \.offset) { index, bounds in
                        Spacer()
                            .frame(height: max((bounds.end - bounds.start) * neckHeight, 1))
                            .overlay(
                                Rectangle()
                                    .fill(Color.white.opacity(((index + 1) % 3 == 0) ? 0.08 : 0))
                                    .frame(height: 1.2)
                                    .opacity(bounds.end >= 1 ? 0 : 1)
                            )
                    }
                }
                .padding(.horizontal, bindingInset)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }

    private func segmentBounds(from ratios: [CGFloat]) -> [(start: CGFloat, end: CGFloat)] {
        guard ratios.count >= 2 else { return [(0, 1)] }
        var pairs: [(CGFloat, CGFloat)] = []
        for index in 0..<(ratios.count - 1) {
            let start = ratios[index]
            let end = ratios[index + 1]
            pairs.append((start, end))
        }
        if let last = ratios.last, last < 1 {
            pairs.append((last, 1))
        }
        return pairs
    }
}

private struct DeveloperButtonStack: View {
    let windowShiftUp: () -> Void
    let windowShiftDown: () -> Void
    let neckShiftUp: () -> Void
    let neckShiftDown: () -> Void
    let canWindowShiftUp: Bool
    let canWindowShiftDown: Bool
    let canNeckShiftUp: Bool
    let canNeckShiftDown: Bool

    var body: some View {
        HStack(spacing: 32) {
            VStack(spacing: 8) {
                devButton(icon: "arrow.up", action: neckShiftUp, isEnabled: canNeckShiftUp)
                devButton(icon: "arrow.down", action: neckShiftDown, isEnabled: canNeckShiftDown)
                Text("NECK")
                    .font(.caption2)
                    .foregroundColor(.white)
                    .bold()
            }
            
            VStack(spacing: 8) {
                devButton(icon: "arrow.up", action: windowShiftUp, isEnabled: canWindowShiftUp)
                devButton(icon: "arrow.down", action: windowShiftDown, isEnabled: canWindowShiftDown)
                Text("WINDOW")
                    .font(.caption2)
                    .foregroundColor(.white)
                    .bold()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.black.opacity(0.45))
                .blur(radius: 2)
        )
    }

    private func devButton(icon: String, action: @escaping () -> Void, isEnabled: Bool) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .bold))
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isEnabled ? 0.95 : 0.4),
                                    Color.white.opacity(isEnabled ? 0.65 : 0.25)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.2), lineWidth: 1)
                        )
                )
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.4), radius: 4, x: 0, y: 3)
                .opacity(isEnabled ? 1 : 0.35)
        }
    }
}

#Preview {
    BeginnerGameplayView()
}

private struct ProjectLinebackerOverlay: View {
    let fretRatios: [CGFloat]
    let neckHeight: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            let neckWidth = geometry.size.width
            let bindingInset = max(neckWidth * 0.02, 6)
            let lineWidth = neckWidth - (bindingInset * 2)
            
            ForEach(1..<fretRatios.count, id: \.self) { index in
                let currentRatio = fretRatios[index]
                let previousRatio = fretRatios[index - 1]
                let midpointRatio = (currentRatio + previousRatio) / 2.0
                let yPosition = midpointRatio * neckHeight
                
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: lineWidth, height: 3)
                    .position(x: neckWidth / 2, y: yPosition)
                    .allowsHitTesting(false)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct GridOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            ZStack {
                // Draw horizontal lines (5 lines creating 6 rows)
                ForEach(1..<6, id: \.self) { index in
                    let yPosition = CGFloat(index) * (height / 6.0)
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: width, height: 1)
                        .position(x: width / 2, y: yPosition)
                        .allowsHitTesting(false)
                }
                
                // Draw vertical lines (5 lines creating 6 columns)
                ForEach(1..<6, id: \.self) { index in
                    let xPosition = CGFloat(index) * (width / 6.0)
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 1, height: height)
                        .position(x: xPosition, y: height / 2)
                        .allowsHitTesting(false)
                }
                
                // Add numbered squares (row-column format: 1a, 1b, 1c, 1d, 1e, 1f for row 1; 2a, 2b, 2c... for row 2)
                ForEach(0..<6, id: \.self) { row in
                    ForEach(0..<6, id: \.self) { col in
                        let xPosition = CGFloat(col) * (width / 6.0) + (width / 12.0)
                        let yPosition = CGFloat(row) * (height / 6.0) + (height / 12.0)
                        let rowNumber = row + 1
                        let aValue = "a".unicodeScalars.first!.value
                        let colValue = aValue + UInt32(col)
                        let colLetter = Character(UnicodeScalar(colValue)!)
                        let label = "\(rowNumber)\(colLetter)"

                        Text(label)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.red.opacity(0.7))
                            .position(x: xPosition, y: yPosition)
                            .allowsHitTesting(false)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

