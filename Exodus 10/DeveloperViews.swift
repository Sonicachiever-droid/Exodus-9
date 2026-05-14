import SwiftUI

#if DEBUG

// MARK: - Developer Button Stack

struct DeveloperButtonStack: View {
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

// MARK: - Purple Guideline Layer

struct PurpleGuidelineLayer: View {
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

// MARK: - Green Bisector Line

struct GreenBisectorLine: View {
    var body: some View {
        Rectangle()
            .fill(Color.green)
            .frame(height: 2)
    }
}

// MARK: - Nut First Fret Highlight

struct NutFirstFretHighlight: View {
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

// MARK: - Developer Code Runner View
// CRT typewriter animation shown in screensaver mode.

struct DeveloperCodeRunnerView: View {
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

// MARK: - Developer Console Frame
// The main console frame hosting all dev/gameplay display content.

struct DeveloperConsoleFrame: View {
    let width: CGFloat
    let height: CGFloat
    let isScreensaverMode: Bool
    let layoutMode: LayoutMode
    let roundTitle: String
    let fretTitle: String
    let stringTitle: String
    let bankText: String
    let scaleRepetitionText: String
    let promptText: String
    let startupElapsed: TimeInterval
    let showStartupSequence: Bool
    let startupShowFullSequence: Bool
    let startupArmedText: String
    let beginnerRoundStatusText: String?
    let centeredStatusMessage: String?
    let centeredStatusColor: Color
    let currentRound: Int
    let repetitionCountColor: Color
    let walletColor: Color
    let hideRoundLabel: Bool
    let pentatonicRevealComplete: Bool
    let noteHighlightIndex: Int?
    let sequentialSlots: [(note: String, stringNumber: Int)]?
    let sequentialRevealCount: Int
    let sequentialAnsweredCount: Int
    let chordSlots: [(note: String, stringNumber: Int)]?
    let chordRevealCount: Int
    let chordAnsweredCount: Int
    let rewardNoteTextByString: [Int: String]?
    var consoleSkin: ConsoleSkin = .classic
    var streakMeterLitSegments: Int? = nil
    var streakMeterFailureActive: Bool = false
    var streakMultiplierFlashText: String? = nil

    private var isHintVisible: Bool {
        promptText.lowercased().hasPrefix("hint:")
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.screenDark, .screenDarkAlt],
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
                    consoleSkin == .tweed
                        ? AnyShapeStyle(Color.white)
                        : AnyShapeStyle(LinearGradient(
                            colors: [
                                Color(red: 0.95, green: 0.82, blue: 0.47),
                                Color(red: 0.78, green: 0.6, blue: 0.22),
                                Color(red: 0.97, green: 0.85, blue: 0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )),
                    lineWidth: 2.5
                )
                .padding(1.5)

            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.black.opacity(0.96), .screenInner, Color.black.opacity(0.96)],
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
                                        VStack(spacing: 0) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 0) {
                                                    Text(scaleRepetitionText)
                                                        .font(.system(size: 20, weight: .black, design: .monospaced))
                                                        .foregroundStyle(repetitionCountColor)
                                                    if hideRoundLabel {
                                                        Text("FRET \(currentRound)")
                                                            .font(.system(size: 20, weight: .black, design: .monospaced))
                                                            .foregroundStyle(Color.white)
                                                    }
                                                }
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

                                            Spacer(minLength: 0)

                                            Spacer(minLength: 0)
                                        }
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                                        if let beginnerRoundStatusText {
                                            let statusLines = beginnerRoundStatusText.components(separatedBy: "\n")
                                            let titleLine: String = statusLines.count >= 2 ? statusLines[0] : ""
                                            let notesLine: String = statusLines.count >= 2 ? statusLines[1] : statusLines[0]
                                            let titleFontSize: CGFloat = 50

                                            if !titleLine.isEmpty || !notesLine.isEmpty {
                                                VStack(spacing: 0) {
                                                    Spacer(minLength: 0)
                                                    if !titleLine.isEmpty {
                                                        Text(titleLine)
                                                            .font(.system(size: titleFontSize, weight: .black, design: .default))
                                                            .foregroundStyle(Color.green.opacity(0.98))
                                                            .minimumScaleFactor(0.2)
                                                            .lineLimit(1)
                                                            .multilineTextAlignment(.center)
                                                            .frame(maxWidth: width * 0.72)
                                                    }
                                                    if titleLine.isEmpty {
                                                        // Single-line: sequential notes or chord name only
                                                        if let slots = sequentialSlots {
                                                            // String-aligned slots: one per physical string
                                                            GeometryReader { slotGeo in
                                                                let centers = GuitarStringLayout.stringCenters(containerWidth: slotGeo.size.width, neckWidth: slotGeo.size.width)
                                                                ZStack {
                                                                    ForEach(Array(slots.enumerated()), id: \.offset) { idx, slot in
                                                                        let stringIndex = GuitarStringLayout.totalStrings - slot.stringNumber
                                                                        let xPos = stringIndex < centers.count ? centers[stringIndex] : slotGeo.size.width / 2
                                                                        let isRevealed = idx < sequentialRevealCount
                                                                        let isAnswered = idx < sequentialAnsweredCount
                                                                        Text(slot.note.replacingOccurrences(of: "#", with: "♯").replacingOccurrences(of: "b", with: "♭"))
                                                                            .font(.system(size: 37, weight: .black, design: .default))
                                                                            .minimumScaleFactor(0.1)
                                                                            .foregroundStyle(idx == sequentialAnsweredCount ? Color.orange : Color.green.opacity(0.98))
                                                                            .position(x: xPos, y: slotGeo.size.height * 0.86 - 15)
                                                                            .opacity(isRevealed && !isAnswered ? 1 : 0)
                                                                    }
                                                                }
                                                            }
                                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                            .allowsHitTesting(false)
                                                        } else {
                                                            let labelMaxWidth = hideRoundLabel ? width * 2 / 3 : .infinity
                                                            let labelAlignment: Alignment = hideRoundLabel ? .top : .bottom
                                                            Text(notesLine)
                                                                .font(.system(size: 50, weight: .black, design: .default))
                                                                .foregroundStyle(Color.green.opacity(0.98))
                                                                .minimumScaleFactor(0.1)
                                                                .lineLimit(1)
                                                                .multilineTextAlignment(.center)
                                                                .frame(maxWidth: labelMaxWidth, maxHeight: height * 2 / 3, alignment: labelAlignment)
                                                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: labelAlignment)
                                                                .allowsHitTesting(false)
                                                        }
                                                    } else {
                                                        // Chord style: string-aligned slots or two-line fallback
                                                        if let slots = chordSlots {
                                                            GeometryReader { chordGeo in
                                                                let centers = GuitarStringLayout.stringCenters(containerWidth: chordGeo.size.width, neckWidth: chordGeo.size.width)
                                                                ZStack {
                                                                    ForEach(Array(slots.enumerated()), id: \.offset) { idx, slot in
                                                                        let stringIndex = GuitarStringLayout.totalStrings - slot.stringNumber
                                                                        let xPos = stringIndex < centers.count ? centers[stringIndex] : chordGeo.size.width / 2
                                                                        let isRevealed = idx < chordRevealCount
                                                                        let isAnswered = idx < chordAnsweredCount
                                                                        let isRewardNote = rewardNoteTextByString != nil
                                                                        let noteColor: Color = {
                                                                            if isRewardNote {
                                                                                return Color.yellow.opacity(0.98)
                                                                            } else if idx == chordAnsweredCount {
                                                                                return Color.orange
                                                                            } else {
                                                                                return Color.green.opacity(0.98)
                                                                            }
                                                                        }()
                                                                        let noteOpacity: Double = {
                                                                            if isRewardNote {
                                                                                return 1.0
                                                                            } else if isRevealed && !isAnswered {
                                                                                return 1.0
                                                                            } else {
                                                                                return 0.0
                                                                            }
                                                                        }()
                                                                        Text(slot.note.replacingOccurrences(of: "#", with: "♯").replacingOccurrences(of: "b", with: "♭"))
                                                                            .font(.system(size: 37, weight: .black, design: .default))
                                                                            .foregroundStyle(noteColor)
                                                                            .position(x: xPos, y: chordGeo.size.height * 0.86 - 15)
                                                                            .opacity(noteOpacity)
                                                                    }
                                                                }
                                                            }
                                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                        } else {
                                                            // Two-line: pentatonic title + notes (fallback)
                                                            VStack(spacing: 0) {
                                                                Text(titleLine)
                                                                    .font(.system(size: 50, weight: .black, design: .default))
                                                                    .foregroundStyle(rewardNoteTextByString != nil ? Color.yellow.opacity(0.98) : Color.green.opacity(0.98))
                                                                    .minimumScaleFactor(0.2)
                                                                    .lineLimit(1)
                                                                    .multilineTextAlignment(.center)
                                                                    .frame(maxWidth: width * 0.72)
                                                                Text(notesLine)
                                                                    .font(.system(size: 50, weight: .black, design: .default))
                                                                    .foregroundStyle(rewardNoteTextByString != nil ? Color.yellow.opacity(0.98) : Color.green.opacity(0.98))
                                                                    .minimumScaleFactor(0.2)
                                                                    .lineLimit(1)
                                                                    .multilineTextAlignment(.center)
                                                                    .frame(maxWidth: width * 0.72)
                                                            }
                                                        }
                                                    }
                                                }
                                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                                                .padding(.bottom, 6)
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
        .overlay(alignment: .bottom) {
            if let lit = streakMeterLitSegments {
                DeveloperTVStreakMeterView(
                    litColumns: lit,
                    failureActive: streakMeterFailureActive
                )
                .padding(.horizontal, 10)
                .padding(.bottom, 8)
            }
        }
        .overlay {
            if let flashText = streakMultiplierFlashText {
                Text(flashText)
                    .font(.system(size: min(width * 0.11, 28), weight: .black, design: .monospaced))
                    .foregroundStyle(Color.yellow.opacity(0.96))
                    .shadow(color: Color.yellow.opacity(0.7), radius: 10, x: 0, y: 0)
                    .shadow(color: Color.orange.opacity(0.5), radius: 20, x: 0, y: 0)
                    .multilineTextAlignment(.center)
                    .transition(.opacity.combined(with: .scale(scale: 1.12)))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .allowsHitTesting(false)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: streakMultiplierFlashText)
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

    private func consoleNotesLineText(_ text: String, fontSize: CGFloat, highlightIndex: Int? = nil) -> Text {
        let tokens = text.split(separator: " ").map(String.init)
        guard tokens.count > 1 else {
            return Text(text)
                .font(.system(size: fontSize, weight: .black, design: .default))
                .foregroundStyle(Color.green.opacity(0.98))
        }

        let attributedString = tokens.enumerated().reduce(AttributedString()) { result, pair in
            let (index, token) = pair
            let suffix = index < tokens.count - 1 ? " " : ""
            var attributedToken = AttributedString("\(token)\(suffix)")
            attributedToken.foregroundColor = index == highlightIndex ? .orange : Color.green.opacity(0.98)
            return result + attributedToken
        }

        return Text(attributedString)
            .font(.system(size: fontSize, weight: .black, design: .default))
    }
}

// MARK: - Developer TV Streak Meter View
// Sequential streak meter: segments fill left-to-right across 3 rows.
// Each correct answer lights one more segment; a wrong answer flashes
// all red then clears back to zero.

struct DeveloperTVStreakMeterView: View {
    let litColumns: Int
    let failureActive: Bool

    private let columnsPerRow: Int = 20
    private let numRows: Int = 3
    private var totalSegments: Int { columnsPerRow * numRows }

    var body: some View {
        let litCount = failureActive ? totalSegments : min(max(litColumns, 0), totalSegments)

        VStack(spacing: 2) {
            ForEach(0..<numRows, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<columnsPerRow, id: \.self) { col in
                        let segIndex = row * columnsPerRow + col
                        let isLit = segIndex < litCount
                        let fillColor: Color = {
                            guard isLit else { return Color(red: 0.10, green: 0.12, blue: 0.10).opacity(0.5) }
                            if failureActive { return Color(red: 1.0, green: 0.22, blue: 0.18).opacity(0.96) }
                            return Color(red: 0.40, green: 1.0, blue: 0.22).opacity(0.96)
                        }()
                        let strokeColor: Color = {
                            guard isLit else { return Color.white.opacity(0.06) }
                            if failureActive { return Color(red: 0.7, green: 0.05, blue: 0.04).opacity(0.9) }
                            return Color(red: 0.08, green: 0.38, blue: 0.04).opacity(0.88)
                        }()
                        let shadowColor: Color = {
                            guard isLit else { return .clear }
                            return failureActive ? Color.red.opacity(0.6) : Color.green.opacity(0.55)
                        }()

                        RoundedRectangle(cornerRadius: 1, style: .continuous)
                            .fill(fillColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 1, style: .continuous)
                                    .stroke(strokeColor, lineWidth: 0.6)
                            )
                            .shadow(color: shadowColor, radius: isLit ? 2 : 0)
                    }
                }
            }
        }
    }
}

#endif
