import SwiftUI
import Combine
import AVFoundation

// GameplayMenuOption and RefretMode are defined in Types.swift

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
        case armed
    }

    let elapsed: TimeInterval

    var body: some View {
        let state = Self.state(for: elapsed)
        let fontSize: CGFloat = 29.6
        let fontWeight: Font.Weight = .black

        Text(state.text)
            .font(.system(size: fontSize, weight: fontWeight, design: .monospaced))
            .foregroundStyle(state.color)
            .multilineTextAlignment(.center)
            .opacity(state.isVisible ? 1 : 0)
            .animation(.easeInOut(duration: 0.08), value: state.isVisible)
    }

    static func state(for elapsed: TimeInterval) -> (text: String, color: Color, isVisible: Bool, phase: Phase) {
        let armedFlashPeriod: TimeInterval = 1.0
        let isVisible = Int(elapsed / armedFlashPeriod).isMultiple(of: 2)
        return ("Memorization Sequence Armed", Color.green.opacity(0.98), isVisible, .armed)
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

// Thumb button glow states

// LED-style thumb button matching the exhibit styling


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
        return "import SwiftUI\nstruct MaestroGameplayView: View {\n    var body: some View {\n        Text(\"Loading Source\")\n    }\n}"
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
    let roundTitle: String
    let fretTitle: String
    let stringTitle: String
    let bankText: String
    let highScoreText: String
    let promptText: String
    let startupElapsed: TimeInterval
    let showStartupSequence: Bool

    var body: some View {
        ZStack {
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

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.black.opacity(0.96), Color(red: 0.07, green: 0.07, blue: 0.08), Color.black.opacity(0.96)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .padding(8)
                .overlay {
                    Group {
                        if isScreensaverMode {
                            ZStack {
                                if !showStartupSequence {
                                    DeveloperCodeRunnerView()
                                        .padding(.horizontal, 12)
                                        .padding(.top, 24)
                                        .padding(.bottom, 10)
                                }

                                if showStartupSequence {
                                    StartupSequenceView(elapsed: startupElapsed)
                                        .padding(.horizontal, 10)
                                        .padding(.top, 24)
                                        .padding(.bottom, 8)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                }
                            }
                        } else {
                            HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("WALLET")
                                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                                .foregroundStyle(Color.white.opacity(0.9))
                                            Text(bankText)
                                                .font(.system(size: 16, weight: .black, design: .monospaced))
                                                .foregroundStyle(Color.green.opacity(0.96))
                                        }

                                        Spacer(minLength: 8)

                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text("HIGH SCORE")
                                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                                .foregroundStyle(Color.white.opacity(0.9))
                                            Text(highScoreText)
                                                .font(.system(size: 16, weight: .black, design: .monospaced))
                                                .foregroundStyle(Color.green.opacity(0.96))
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(maxHeight: .infinity, alignment: .top)

                                    VStack(spacing: 4) {
                                        Text("PHASE 1")
                                            .font(.system(size: 16, weight: .black, design: .monospaced))
                                            .foregroundStyle(Color.red.opacity(0.96))
                                        Text(roundTitle)
                                            .font(.system(size: 16, weight: .black, design: .monospaced))
                                            .foregroundStyle(Color.blue.opacity(0.96))
                                        Text("\(stringTitle)   \(fretTitle)")
                                            .font(.system(size: 15, weight: .black, design: .monospaced))
                                            .foregroundStyle(Color.yellow.opacity(0.96))

                                        if !promptText.isEmpty {
                                            Text(promptText)
                                                .font(.system(size: 12, weight: .black, design: .monospaced))
                                                .foregroundStyle(Color.orange.opacity(0.98))
                                                .multilineTextAlignment(.center)
                                                .lineLimit(3)
                                                .minimumScaleFactor(0.75)
                                                .padding(.top, 4)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                    .multilineTextAlignment(.leading)
                                    .padding(.horizontal, 14)
                                    .padding(.top, 22)
                                    .padding(.bottom, 10)
                        }
                    }
                }
                .padding(8)
        }
        .frame(width: width, height: height)
    }
}

private struct WhiteNoteBoxOverlay: View {
    let centerY: CGFloat
    let availableSize: CGSize
    let boxHeight: CGFloat
    let neckWidth: CGFloat
    let activeStringNumbers: [Int]
    let answerFeedback: ThumbGlowState?
    let currentQuestionIsAccidental: Bool
    let blinkingActive: Bool
    let blinkOrange: Bool
    let revealedNote: String?

    private let totalStrings: Int = 6
    private let stratNutWidthInches: CGFloat = 1.650
    private let stratStringSpanInches: CGFloat = 1.362

    var body: some View {
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
                let fillColor: Color = {
                    guard isActive else { return Color.clear }
                    switch answerFeedback {
                    case .red:
                        return Color(red: 0.48, green: 0.06, blue: 0.06).opacity(0.9)
                    default:
                        return currentQuestionIsAccidental ? Color.black.opacity(0.95) : Color.white.opacity(0.92)
                    }
                }()
                let strokeColor: Color = {
                    guard isActive else { return .clear }
                    switch answerFeedback {
                    case .red: return Color(red: 0.48, green: 0.06, blue: 0.06).opacity(0.9)
                    default:
                        return currentQuestionIsAccidental ? Color.white.opacity(0.86) : Color.black.opacity(0.72)
                    }
                }()
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(fillColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(strokeColor, lineWidth: 2)
                        )
                    if isActive, let revealedNote {
                        Text(revealedNote)
                            .font(.system(size: clampedBoxHeight * 0.38, weight: .black, design: .default))
                            .foregroundColor(currentQuestionIsAccidental ? .white : .black)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                }
                .frame(width: boxWidth, height: clampedBoxHeight)
                .position(x: grooveCenters[index], y: centerY)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: activeStringNumbers)
        .animation(.easeInOut(duration: 0.18), value: answerFeedback)
    }
}


private struct RowOneIdentifierOverlay: View {
    let leftLabel: String
    let rightLabel: String
    let size: CGSize
    let rowHeight: CGFloat

    var body: some View {
        let bannerFont = UIFont.systemFont(ofSize: 18, weight: .semibold)
        let measuredWidth = max(
            textWidth(for: leftLabel, font: bannerFont),
            textWidth(for: rightLabel, font: bannerFont),
            textWidth(for: "Open Strings", font: bannerFont)
        )
        let bannerWidth = measuredWidth + 32
        let bannerHeight = max(min(rowHeight * 0.66, 50), 40)

        return HStack(spacing: 16) {
            MiniTVFrame(text: leftLabel, width: bannerWidth, height: bannerHeight, fontScale: 0.82)
            MiniTVFrame(text: rightLabel, width: bannerWidth, height: bannerHeight, fontScale: 0.82)
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



private struct BrassStringView: View {
    let stringX: CGFloat
    let stringHeight: CGFloat
    let stringTopY: CGFloat
    let stringNumber: Int
    
    private var stringThickness: CGFloat {
        switch stringNumber {
        case 6: return 4.0
        case 5: return 3.5
        case 4: return 3.0
        default: return 2.5
        }
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: stringThickness / 2, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.96, green: 0.94, blue: 0.88),
                        Color(red: 0.82, green: 0.69, blue: 0.47),
                        Color(red: 0.65, green: 0.50, blue: 0.30),
                        Color(red: 0.85, green: 0.75, blue: 0.60)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: stringThickness / 2)
                    .stroke(Color.black.opacity(0.2), lineWidth: 0.3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: stringThickness / 2)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.6), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 0.5)
            .frame(width: stringThickness, height: max(stringHeight, 2))
            .position(x: stringX, y: stringTopY + stringHeight / 2)
    }
}

private struct BrassStringSegment: View {
    let width: CGFloat
    let height: CGFloat
    let segmentIndex: Int
    let totalSegments: Int
    
    var body: some View {
        RoundedRectangle(cornerRadius: width / 2, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.96, green: 0.94, blue: 0.88),
                        Color(red: 0.82, green: 0.69, blue: 0.47),
                        Color(red: 0.65, green: 0.50, blue: 0.30),
                        Color(red: 0.85, green: 0.75, blue: 0.60)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: width / 2)
                    .stroke(Color.black.opacity(0.2), lineWidth: 0.3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: width / 2)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.6), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 0.5)
            .frame(width: width, height: max(height, 2))
    }
}






struct MaestroGameplayView: View {
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

    @Environment(\.displayScale) private var displayScale
    private let totalFrets: Int = 20
    private var maxFretOffset: Int { totalFrets }
    private var minFretOffset: Int { -totalFrets }

    private var isPhaseDescending: Bool {
        [2, 4, 6, 8, 10, 12].contains(selectedPhase)
    }

    private var usesRandomStringOrder: Bool {
        [5, 6].contains(selectedPhase)
    }

    private var phaseLabel: String {
        "PHASE \(selectedPhase)"
    }

    private var activeStringOrder: [Int] {
        switch selectedMode {
        case .oneHand:
            return [1, 2, 3, 4]
        default:
            return [1, 2, 3, 4, 5, 6]
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
    private let codenameNemoEnabled: Bool = false
    private let scaleLengthInches: Double = 25.5
    private let debugGridRows: Int = 8
    private var maxWindowRow: Int { (debugGridRows - 1) * 2 } // half-step increments across rows
    @State private var currentFretStart: Int = 0
    @State private var currentWindowRow: Int = 2
    @State private var leftThumbState: ThumbGlowState = .neutral
    @State private var rightThumbState: ThumbGlowState = .neutral
    @State private var currentRound: Int = 0
    @State private var roundStringIndex: Int = 0
    @State private var isDescendingPhase: Bool = false
    @State private var leftChoiceNote: String = ""
    @State private var rightChoiceNote: String = ""
    @State private var correctAnswerSide: AnswerSide = .left
    @State private var isResolvingAnswer: Bool = false
    @State private var activePickedStringNumbers: [Int] = [1]
    @State private var activeAnswerFeedback: ThumbGlowState? = nil
    @State private var currentQuestionIsAccidental: Bool = false
    @State private var introWindowBlack: Bool = true
    @State private var introDidRun: Bool = false
    @State private var isCodeScreensaverMode: Bool = true
    @State private var cachedStringStatusLabel: String = ""
    @State private var cachedFretStatusLabel: String = ""
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
    @State private var isRoundPaused: Bool = false
    @State private var transportStoppedForResume: Bool = false
    @State private var showFretboardGuide: Bool = false
    @State private var isLaunchTransitionAnimating: Bool = false
    @State private var launchTileScale: CGFloat = 1
    @State private var launchTileOpacity: Double = 1
    @State private var beatPulseActive: Bool = false
    @State private var beatCountInRemaining: Int = 0
    @State private var nextBeatTickDate: Date? = nil
    @State private var beatLightFlashOn: Bool = false
    @State private var beatLightLastProcessedBeat: Int? = nil
    @State private var questionBoxPulsePhase: Bool = false
    @State private var nextQuestionBoxPulseDate: Date? = nil
    @State private var questionBoxIntroProgress: CGFloat = 0
    @State private var autoPlayEnabled: Bool = false
    @State private var autoPlayNextDate: Date? = nil

    private enum StartupSpeechPhase {
        case idle
        case pendingArmed
    }

    @State private var startupSpeechPhase: StartupSpeechPhase = .idle
    @State private var audioSettings = AudioSettings()
    @State private var availableBackingTracks: [BackingTrack] = []
    @State private var showAudioPage: Bool = false

    private let audioEngine = GameplayAudioEngine()
    private let guitarNoteEngine: GuitarNotePlaying = GuitarNoteEngine.shared
    private let midiEngine: BackingTrackPlaying = SimpleMIDIEngine()
    private let audioEngineEnabled: Bool = false
    private let speakBeatTicks: Bool = false
    private let speakGameplayPrompts: Bool = false

    init(
        onMenuSelection: ((GameplayMenuOption) -> Void)? = nil,
        selectedMode: RefretMode = .freestyle,
        selectedPhase: Int = 1,
        beatBPM: Int = 80,
        beatVolume: Double = 0.8,
        stringVolume: Double = 0.8,
        playStartingFret: Binding<Int> = .constant(0),
        playRepetitions: Binding<Int> = .constant(0),
        playDirectionRawValue: Binding<String> = .constant(""),
        playEnableHighFrets: Binding<Bool> = .constant(false),
        playLessonStyle: Binding<String> = .constant(""),
        walletDollars: Binding<Int> = .constant(0),
        balanceDollars: Binding<Int> = .constant(0)
    ) {
        self.onMenuSelection = onMenuSelection
        self.selectedMode = selectedMode
        self.selectedPhase = min(max(selectedPhase, 1), 12)
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
            let isGameplayStarted = !isCodeScreensaverMode
            let displayedFretStatusLabel = isGameplayStarted ? cachedFretStatusLabel : ""
            let displayedStringStatusLabel = isGameplayStarted ? cachedStringStatusLabel : ""
            let roundStatusLabel = "ROUND \(currentRound + 1)"
            let screenBannerFont = UIFont.systemFont(ofSize: 20, weight: .semibold)
            let screenMeasuredWidth = max(
                textWidth(for: cachedFretStatusLabel, font: screenBannerFont),
                textWidth(for: cachedStringStatusLabel, font: screenBannerFont),
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
            let whitePipingWidth = max(proxy.size.width - 7, 0)
            let noteChoiceY = upperWhitePipingY - (lowerScreenHeight / 2) - 2
            let developerOverlaysEnabled: Bool = false
            let windowTopY = holeCenterY - highlightHeight / 2
            let topStatusOuterWidth = highlightWidth
            let topStatusOuterHeight = max(min(gridRowHeight * 1.35, 120), 74)
            let topStatusBottomGap = max(gridRowHeight * 0.18, 10)
            let topStatusCenterY = (windowTopY - topStatusBottomGap) - (topStatusOuterHeight / 2)

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
                guard isCodeScreensaverMode else {
                    return ("", .clear, false, .armed)
                }
                guard startupSequenceActivated else {
                    return ("", .clear, false, .armed)
                }
                return StartupSequenceView.state(for: startupSequenceElapsed)
            }()
            let screensaverThumbState: ThumbGlowState = {
                guard startupState.isVisible else { return .neutral }
                return .green
            }()
            let effectiveLeftThumbState = isCodeScreensaverMode ? screensaverThumbState : leftThumbState
            let effectiveRightThumbState = isCodeScreensaverMode ? screensaverThumbState : rightThumbState
            let startButtonBlinkOn = isCodeScreensaverMode && startupState.isVisible
            let initialGameplayDimOpacity: CGFloat = (isCodeScreensaverMode && !startupSequenceActivated) ? 0.42 : 1.0
            let sideWindowGap = max((proxy.size.width - highlightWidth) / 4, 18)
            let leftFretIndicatorX = (proxy.size.width / 2) - (highlightWidth / 2) - sideWindowGap
            let rightFretIndicatorX = (proxy.size.width / 2) + (highlightWidth / 2) + sideWindowGap
            let fretIndicatorText = "\(min(max(currentRound, 0), 12))"

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

                StringLineOverlay(
                    neckWidth: neckWidth,
                    horizontalPadding: padding,
                    stringTopY: stringTopY
                )

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

                if showFretboardGuide && !isCodeScreensaverMode {
                    let guideBoxHeight = topStatusOuterHeight * 0.5
                    let guideBoxCenterY = windowBottomY - (guideBoxHeight / 2) - 4
                    let stringCenters = GuitarStringLayout.stringCenters(containerWidth: proxy.size.width, neckWidth: neckWidth)
                    let centerSpacings = (1..<stringCenters.count).map { stringCenters[$0] - stringCenters[$0 - 1] }
                    let minCenterSpacing = centerSpacings.min() ?? 60
                    let spacingGap = max(minCenterSpacing * 0.12, 6)
                    let maxBoxWidthFromSpacing = max(minCenterSpacing - spacingGap, 0)
                    let boxWidth = min(guideBoxHeight * 1.8, maxBoxWidthFromSpacing)
                    let fretboardStrings = (0..<GuitarStringLayout.totalStrings).map { GuitarStringLayout.highestStringNumber - $0 }
                    ZStack {
                        // Six individual translucent backgrounds for each note box
                        ForEach(Array(fretboardStrings.enumerated()), id: \.offset) { index, _ in
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.black.opacity(0.42))
                                .frame(width: boxWidth, height: guideBoxHeight)
                                .position(x: stringCenters[index], y: guideBoxCenterY)
                        }

                        ForEach(Array(fretboardStrings.enumerated()), id: \.offset) { index, stringNumber in
                            let note: String = noteName(forString: stringNumber, fret: max(currentRound, 0), useFlats: false)
                            let isAccidental: Bool = note.contains("#") || note.contains("b")
                            let fillColor: Color = isAccidental ? Color.black.opacity(0.95) : Color.white.opacity(0.92)
                            let strokeColor: Color = isAccidental ? Color.white.opacity(0.86) : Color.black.opacity(0.72)
                            let textColor: Color = isAccidental ? Color.white.opacity(0.96) : Color.black
                            let textSize = min(guideBoxHeight * 0.78, 28)
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(fillColor)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(strokeColor, lineWidth: 2)
                                )
                                .overlay(
                                    Text(note)
                                        .font(.system(size: textSize, weight: .black, design: .monospaced))
                                        .foregroundStyle(textColor)
                                        .minimumScaleFactor(0.32)
                                        .lineLimit(1)
                                )
                                .frame(width: boxWidth, height: guideBoxHeight)
                                .position(x: stringCenters[index], y: guideBoxCenterY)
                        }
                    }
                    .allowsHitTesting(false)
                }

                fretIndicatorOverlay(
                    leftX: leftFretIndicatorX,
                    rightX: rightFretIndicatorX,
                    centerY: orangeGreenUnitCenterY,
                    text: fretIndicatorText,
                    isHidden: isCodeScreensaverMode
                )

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
                    roundTitle: "\(phaseLabel) • \(roundStatusLabel)",
                    fretTitle: displayedFretStatusLabel,
                    stringTitle: displayedStringStatusLabel,
                    bankText: "$\(displayedBankDollars)",
                    highScoreText: "$\(highScoreDollars)",
                    promptText: developerPromptText,
                    startupElapsed: startupSequenceElapsed,
                    showStartupSequence: startupSequenceActivated,
                )
                .position(x: proxy.size.width / 2, y: topStatusCenterY)
                .allowsHitTesting(false)
                .opacity(codenameNemoEnabled ? 0 : 1)

                let introScale = max(questionBoxIntroProgress, 0.001)
                let introOffsetY = (1 - questionBoxIntroProgress) * ((proxy.size.height / 2) - topScreenY)
                let questionBoxOffsetY = (1 - questionBoxIntroProgress) * ((proxy.size.height / 2) - orangeGreenUnitCenterY)
                let shouldShowQuestionUI = !isCodeScreensaverMode && !startupSequenceActivated && questionBoxIntroProgress > 0.0

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
                    .opacity(codenameNemoEnabled ? 0 : initialGameplayDimOpacity * introScale)

                    // Blue beat light (left side)
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 12, height: 12)
                        .shadow(color: Color(red: 0.28, green: 0.7, blue: 1.0).opacity(0.95), radius: 12)
                        .shadow(color: Color.white.opacity(0.45), radius: 5)
                        .overlay(Circle().stroke(Color.white.opacity(0.75), lineWidth: 1))
                        .position(x: leftAnswerCenterX - lowerScreenWidth/2 - 16, y: noteChoiceY)
                        .opacity(beatLightFlashOn ? 1 : 0)
                        .animation(.easeOut(duration: 0.08), value: beatLightFlashOn)
                        .allowsHitTesting(false)

                    MiniTVFrame(text: leftChoiceNote, width: lowerScreenWidth, height: lowerScreenHeight, fontScale: 1.0, isDarkScreen: leftChoiceNote.contains("#") || leftChoiceNote.contains("b"))
                        .position(x: leftAnswerCenterX, y: noteChoiceY)
                        .allowsHitTesting(false)
                        .opacity(codenameNemoEnabled ? 0 : introScale)

                    MiniTVFrame(text: rightChoiceNote, width: lowerScreenWidth, height: lowerScreenHeight, fontScale: 1.0, isDarkScreen: rightChoiceNote.contains("#") || rightChoiceNote.contains("b"))
                        .position(x: rightAnswerCenterX, y: noteChoiceY)
                        .allowsHitTesting(false)
                        .opacity(codenameNemoEnabled ? 0 : introScale)

                    WhiteNoteBoxOverlay(
                        centerY: orangeGreenUnitCenterY,
                        availableSize: proxy.size,
                        boxHeight: gridRowHeight * 0.9,
                        neckWidth: neckWidth,
                        activeStringNumbers: activePickedStringNumbers,
                        answerFeedback: activeAnswerFeedback,
                        currentQuestionIsAccidental: currentQuestionIsAccidental,
                        blinkingActive: false,
                        blinkOrange: false,
                        revealedNote: activeAnswerFeedback == .green ? currentCorrectNote : nil
                    )
                    .allowsHitTesting(false)
                    .offset(y: questionBoxOffsetY)
                    .opacity(codenameNemoEnabled ? 0 : initialGameplayDimOpacity)
                }

                GoldHorizontalPipingLine(width: whitePipingWidth)
                    .position(x: proxy.size.width / 2, y: upperWhitePipingY)
                    .allowsHitTesting(false)
                    .opacity(codenameNemoEnabled ? 0 : 1)

                GoldHorizontalPipingLine(width: whitePipingWidth)
                    .position(x: proxy.size.width / 2, y: lowerWhitePipingY)
                    .allowsHitTesting(false)
                    .opacity(codenameNemoEnabled ? 0 : 1)

                GoldPipingBorder(bottomInset: 0)
                    .allowsHitTesting(false)
                    .offset(y: -globalContentShiftY)
                    .zIndex(100)

            }
            .overlay {
                debugGridOverlay(size: proxy.size, columns: debugGridColumns, rows: debugGridRows)
                    .allowsHitTesting(false)
                    .opacity(developerOverlaysEnabled ? 0.8 : 0)
            }
            .overlay {
                let maestroTransportCenterY = lowerWhitePipingY + (proxy.size.height - lowerWhitePipingY) * 0.28
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
                    Button("STOP") { handleMaestroStopButton() }
                        .frame(minWidth: 58, minHeight: 34, maxHeight: 34)
                        .disabled(isCodeScreensaverMode || isRoundPaused)
                        .background(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .stroke(Color.black.opacity(0.34), lineWidth: 1.0)
                        )
                    Button("RESET") { handleMaestroResetButton() }
                        .frame(minWidth: 58, minHeight: 34, maxHeight: 34)
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
                .position(x: proxy.size.width / 2, y: maestroTransportCenterY)
                .opacity(codenameNemoEnabled ? 0 : 1)
            }
            .overlay(alignment: .bottom) {
                GameplayControlPlateShell(
                    isMenuExpanded: gameplayMenuExpanded,
                    isStartupInputLockActive: false,
                    isAutoplayActive: autoPlayEnabled,
                    onAutoplay: {
                        autoPlayEnabled.toggle()
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
                .opacity(codenameNemoEnabled ? 0 : initialGameplayDimOpacity)
            }
            .onAppear {
                if assetToNutBottomDelta == nil {
                    assetToNutBottomDelta = 0
                }
                guard !introDidRun else { return }
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
                availableBackingTracks = BackingTrack.discoverBundledTracks()
                audioSettings.selectInitialBackingTrackIfNeeded(from: availableBackingTracks)
            }
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
            .onChange(of: autoPlayEnabled) { _, isEnabled in
                guard isEnabled else {
                    autoPlayNextDate = nil
                    return
                }
                autoPlayNextDate = Date().addingTimeInterval(0.38)
            }
            .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { date in
                if isRoundPaused {
                    return
                }

                if startupSequenceActivated {
                    startupSequenceElapsed = max(date.timeIntervalSince(startupSequenceStartDate), 0)
                    let startupState = StartupSequenceView.state(for: startupSequenceElapsed)
                    handleStartupSpeech(for: startupState.phase)
                }

                if !isCodeScreensaverMode {
                    let bpm = Double(max(beatBPM, 60))
                    let beatInterval = max(0.25, 60.0 / bpm)
                    if nextBeatTickDate == nil {
                        nextBeatTickDate = date.addingTimeInterval(beatInterval)
                    }

                    if let nextBeatTickDate, date >= nextBeatTickDate {
                        self.nextBeatTickDate = nextBeatTickDate.addingTimeInterval(beatInterval)
                        beatPulseActive = true
                        if audioEngineEnabled && speakBeatTicks {
                            audioEngine.playBeat(volume: beatVolume)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                            beatPulseActive = false
                        }

                        if beatCountInRemaining > 0 {
                            beatCountInRemaining -= 1
                            showDeveloperPrompt("COUNT IN: \(beatCountInRemaining)")
                        }

                    }
                } else {
                    nextBeatTickDate = nil
                    beatPulseActive = false
                }

                // Handle beat light flash and neck shift countdown using actual MIDI beat position
                if !isCodeScreensaverMode, midiEngine.isPlaying {
                    let currentBeat = midiEngine.currentBeatPosition()
                    let currentBeatBucket = Int(floor(currentBeat))

                    // Blue beat light flash
                    if beatLightLastProcessedBeat == nil {
                        beatLightLastProcessedBeat = currentBeatBucket
                    } else if beatLightLastProcessedBeat != currentBeatBucket {
                        beatLightLastProcessedBeat = currentBeatBucket
                        beatLightFlashOn = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                            beatLightFlashOn = false
                        }
                    }
                }

                let shouldPulseQuestionBox = !isCodeScreensaverMode && !isResolvingAnswer
                if shouldPulseQuestionBox {
                    if nextQuestionBoxPulseDate == nil {
                        nextQuestionBoxPulseDate = date.addingTimeInterval(1.0)
                    }
                    if let nextQuestionBoxPulseDate, date >= nextQuestionBoxPulseDate {
                        questionBoxPulsePhase.toggle()
                        self.nextQuestionBoxPulseDate = nextQuestionBoxPulseDate.addingTimeInterval(1.0)
                    }
                } else {
                    questionBoxPulsePhase = false
                    nextQuestionBoxPulseDate = nil
                }

                handleMaestroAutoPlayIfNeeded(currentDate: date)
            }
            .offset(y: globalContentShiftY)
        }
    }

    private func shiftFretSpan(by delta: Int) {
        guard delta != 0 else { return }
        withAnimation(.easeInOut(duration: 0.5)) {
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

    private func handleMaestroAutoPlayIfNeeded(currentDate: Date) {
        guard autoPlayEnabled,
              !isCodeScreensaverMode,
              !startupSequenceActivated,
              !isResolvingAnswer,
              !isRoundPaused
        else {
            if !autoPlayEnabled {
                autoPlayNextDate = nil
            }
            return
        }

        guard let nextDate = autoPlayNextDate, currentDate >= nextDate else { return }

        // Submit the correct answer
        submitAnswer(correctAnswerSide, force: true)
        autoPlayNextDate = currentDate.addingTimeInterval(0.38)
    }

    private func startGameFromBeginning() {
        currentRound = isPhaseDescending ? 12 : 0
        roundStringIndex = 0
        isDescendingPhase = isPhaseDescending
        bankDollars = 0
        displayedBankDollars = 0
        walletDollars = 0
        currentPromptStrings = [1]
        activePickedStringNumbers = [1]
        beatCountInRemaining = 4
        nextBeatTickDate = nil
        leftThumbState = .neutral
        rightThumbState = .neutral
        activeAnswerFeedback = nil
        isResolvingAnswer = false
        gameplayMenuExpanded = false
        developerPromptText = ""
        currentCorrectNote = ""
        lastResolvedCorrectNote = nil
        lastResolvedCorrectString = nil
        beatLightFlashOn = false
        beatLightLastProcessedBeat = nil
        autoPlayNextDate = nil
        midiEngine.setBassTransposeSemitones(0)
        prepareCurrentQuestion()
    }

    private func submitAnswer(_ side: AnswerSide, force: Bool = false) {
        if isCodeScreensaverMode {
            if !startupSequenceActivated {
                startupSequenceActivated = true
                startupSequenceStartDate = .now
                startupSequenceElapsed = 0
                questionBoxIntroProgress = 0
                return
            }

            guard !isLaunchTransitionAnimating else { return }

            isLaunchTransitionAnimating = true
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
                currentFretStart = isPhaseDescending ? maxFretOffset : minFretOffset
                startGameFromBeginning()
                syncMaestroBackingTrack()
                isLaunchTransitionAnimating = false
                launchTileScale = 1
                launchTileOpacity = 1
                withAnimation(.easeOut(duration: 0.6)) {
                    questionBoxIntroProgress = 1
                }
            }
            return

        }

        guard force || !isResolvingAnswer else { return }
        isResolvingAnswer = true

        let isCorrect = side == correctAnswerSide
        if isCorrect {
            withAnimation(.none) {
                leftThumbState = .green
                rightThumbState = .green
                activeAnswerFeedback = .green
            }
            lastResolvedCorrectNote = currentCorrectNote
            lastResolvedCorrectString = currentPromptStrings.first
            for (index, stringNumber) in currentPromptStrings.enumerated() {
                let delay = Double(index) * 0.035
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    guitarNoteEngine.play(string: stringNumber, fret: max(currentRound, 0), velocity: 0.98)
                }
            }
        } else {
            withAnimation(.none) {
                leftThumbState = .red
                rightThumbState = .red
                activeAnswerFeedback = .red
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            leftThumbState = .neutral
            rightThumbState = .neutral
            questionBoxAssistActive = false
            if isCorrect {
                advanceGame(afterCorrectAnswer: true)
            } else {
                advanceGame(afterCorrectAnswer: false)
            }
        }
    }

    private func handleMaestroStartButton() {
        if isCodeScreensaverMode {
            if !startupSequenceActivated {
                startupSequenceActivated = true
                startupSequenceStartDate = .now
                startupSequenceElapsed = 0
                questionBoxIntroProgress = 0
                return
            }
            guard !isLaunchTransitionAnimating else { return }
            isLaunchTransitionAnimating = true
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
                currentFretStart = isPhaseDescending ? maxFretOffset : minFretOffset
                startGameFromBeginning()
                isLaunchTransitionAnimating = false
                launchTileScale = 1
                launchTileOpacity = 1
                isRoundPaused = false
                transportStoppedForResume = false
                syncMaestroBackingTrack()
                withAnimation(.easeOut(duration: 0.6)) {
                    questionBoxIntroProgress = 1
                }
            }
            return
        }

        if transportStoppedForResume {
            isRoundPaused = false
            transportStoppedForResume = false
            nextBeatTickDate = nil
            beatLightLastProcessedBeat = nil
            syncMaestroBackingTrack(allowResumeFromPause: true)
            return
        }
    }

    private func handleMaestroStopButton() {
        guard !isCodeScreensaverMode, !isRoundPaused else { return }
        isRoundPaused = true
        transportStoppedForResume = true
        nextBeatTickDate = nil
        beatPulseActive = false
        beatLightFlashOn = false
        beatLightLastProcessedBeat = nil
        midiEngine.pause()
    }

    private func handleMaestroResetButton() {
        isRoundPaused = false
        transportStoppedForResume = false
        nextBeatTickDate = nil
        beatPulseActive = false
        midiEngine.stop()
        isCodeScreensaverMode = true
        startupSequenceActivated = true
        startupSequenceStartDate = .now
        startupSequenceElapsed = 0
        startupSpeechPhase = .pendingArmed
        questionBoxIntroProgress = 0
        isLaunchTransitionAnimating = false
        launchTileScale = 1
        launchTileOpacity = 1
        startGameFromBeginning()
        // Note: startGameFromBeginning now handles the transpose restart
        beatLightFlashOn = false
        beatLightLastProcessedBeat = nil
        autoPlayNextDate = nil
        autoPlayEnabled = false
    }

    private func syncMaestroBackingTrack(allowResumeFromPause: Bool = false) {
        if availableBackingTracks.isEmpty {
            availableBackingTracks = BackingTrack.discoverBundledTracks()
        }
        guard !availableBackingTracks.isEmpty else {
            midiEngine.stop()
            return
        }
        audioSettings.selectInitialBackingTrackIfNeeded(from: availableBackingTracks)
        guard let selectedTrackID = audioSettings.selectedBackingTrackID,
              let selectedTrack = availableBackingTracks.first(where: { $0.id == selectedTrackID }),
              let trackURL = selectedTrack.resourceURL() else {
            midiEngine.stop()
            return
        }
        if allowResumeFromPause {
            midiEngine.resume()
            return
        }
        if midiEngine.isPlaying, midiEngine.activeURL == trackURL {
            return
        }
        midiEngine.play(url: trackURL, title: selectedTrack.title, loop: true)
    }

    private func purchaseAnswerFromQuestionBox() {
        guard !isCodeScreensaverMode, !isResolvingAnswer else { return }
        let charge = max(1, payoutForRound(currentRound))
        bankDollars = max(bankDollars - charge, 0)
        displayedBankDollars = bankDollars
        walletDollars = bankDollars

        questionBoxAssistActive = true
        if correctAnswerSide == .left {
            leftThumbState = .orange
            rightThumbState = .neutral
        } else {
            leftThumbState = .neutral
            rightThumbState = .orange
        }

        isResolvingAnswer = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            submitAnswer(correctAnswerSide, force: true)
        }
    }

    private func advanceGame(afterCorrectAnswer isCorrect: Bool) {
        if !isCorrect {
            animateBankResetToZero {
                startGameFromBeginning()
                isResolvingAnswer = false
            }
            return
        }

        let payout = payoutForRound(currentRound)
        bankDollars += payout
        displayedBankDollars = bankDollars
        walletDollars = bankDollars
        balanceDollars += payout
        highScoreDollars = max(highScoreDollars, bankDollars)

        // Advance to next string in round
        if usesRandomStringOrder {
            roundStringIndex = Int.random(in: 0..<max(activeStringOrder.count, 1))
        } else if roundStringIndex < activeStringOrder.count - 1 {
            roundStringIndex += 1
        } else {
            // Round complete - all strings answered, shift to next round immediately
            roundStringIndex = 0
            if !isPhaseDescending {
                if currentRound < 12 {
                    currentRound += 1
                } else {
                    currentRound = 0
                }
            } else {
                if currentRound > 0 {
                    currentRound -= 1
                } else {
                    currentRound = 12
                }
            }
            // Immediate bass transpose
            midiEngine.setBassTransposeSemitones(max(currentRound, 0) % 12)
            // Immediate neck shift with animation
            withAnimation(.easeInOut(duration: 0.9)) {
                currentFretStart = max(currentRound, 0)
            }
        }
        prepareCurrentQuestion()
        isResolvingAnswer = false
    }

    private func prepareCurrentQuestion() {
        let targetString = activeStringOrder[min(max(roundStringIndex, 0), activeStringOrder.count - 1)]
        currentPromptStrings = [targetString]

        let noteString = currentPromptStrings.first ?? targetString
        let fret = max(currentRound, 0)
        let useFlats = false
        let correctNote = noteName(forString: noteString, fret: fret, useFlats: useFlats)
        let incorrectNote = randomIncorrectNote(excluding: correctNote, useFlats: useFlats)

        let correctOnLeft = Bool.random()

        if correctOnLeft {
            leftChoiceNote = correctNote
            rightChoiceNote = incorrectNote
            correctAnswerSide = .left
        } else {
            leftChoiceNote = incorrectNote
            rightChoiceNote = correctNote
            correctAnswerSide = .right
        }

        currentCorrectNote = correctNote

        activePickedStringNumbers = currentPromptStrings
        currentQuestionIsAccidental = correctNote.contains("#") || correctNote.contains("b")
        activeAnswerFeedback = nil
        questionBoxAssistActive = false

        // Cache labels so they stay in sync with the question
        cachedFretStatusLabel = fret == 0 ? "OPEN" : "FRET \(fret)"
        cachedStringStatusLabel = "STRING \(currentPromptStrings[0])"

        if audioEngineEnabled && speakGameplayPrompts {
            let promptSpoken = currentPromptStrings.count > 1
                ? currentPromptStrings.map { "string \($0)" }.joined(separator: " and ")
                : "string \(targetString)"
            audioEngine.playNotePrompt(promptSpoken, volume: stringVolume)
        }

        withAnimation(.easeInOut(duration: 0.9)) {
            currentFretStart = fret
        }
    }

    private func payoutForRound(_ round: Int) -> Int {
        let clamped = min(max(round, 0), 20)
        let baseValue = Int(pow(2.0, Double(clamped)))
        return max(1, Int((Double(baseValue) * modePayoutMultiplier).rounded()))
    }

    private func animateBankResetToZero(completion: @escaping () -> Void) {
        let startValue = displayedBankDollars
        guard startValue > 0 else {
            bankDollars = 0
            displayedBankDollars = 0
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
        let correctIsAccidental = correct.contains("#") || correct.contains("b")
        let pool = source.filter { note in
            note != correct && (note.contains("#") || note.contains("b")) == correctIsAccidental
        }
        return pool.randomElement() ?? (correctIsAccidental ? "C#" : "C")
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

    private func handleStartupSpeech(for phase: StartupSequenceView.Phase) {
        guard audioEngineEnabled else { return }
        switch phase {
        case .armed:
            if startupSpeechPhase == .pendingArmed {
                speakStartup("Memorization Sequence Armed")
                startupSpeechPhase = .idle
            }
        }
    }

    private func speakStartup(_ phrase: String) {
        audioEngine.speakStartupAlert(phrase, volume: stringVolume)
    }

    private func handleFretboardButtonPress() {
        showFretboardGuide.toggle()
        showDeveloperPrompt(showFretboardGuide ? "Fretboard guide ON" : "Fretboard guide OFF")
    }


    private func showDeveloperPrompt(_ text: String) {
        developerPromptText = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            if developerPromptText == text {
                developerPromptText = ""
            }
        }
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

private extension MaestroGameplayView {
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
    MaestroGameplayView()
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

