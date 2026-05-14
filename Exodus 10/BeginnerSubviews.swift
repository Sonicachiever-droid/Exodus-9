import SwiftUI
import Combine
import AVFoundation

// MARK: - White Note Box Overlay
// Answer boxes shown above each guitar string at the active fret.

struct WhiteNoteBoxOverlay: View {
    let centerY: CGFloat
    let availableSize: CGSize
    let boxHeight: CGFloat
    let neckWidth: CGFloat
    let activeStringNumbers: [Int]
    let answerFeedback: ThumbGlowState?
    var showFeedbackColors: Bool = true   // false in Maestro — boxes stay neutral on correct answers
    let revealedNoteText: String?
    let revealedNoteTextByString: [Int: String]?
    let revealedNoteTextColor: Color

    var body: some View {
        let totalStrings = GuitarStringLayout.totalStrings
        let stratNutWidthInches: CGFloat = GuitarConstants.stratNutWidth
        let stratStringSpanInches: CGFloat = GuitarConstants.stratStringSpan
        let clampedBoxHeight = min(boxHeight, availableSize.height)
        let nutWidth = neckWidth * GuitarConstants.nutWidthRatio
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
        let spacingGap = max(minCenterSpacing * GuitarConstants.stringGapMultiplier, 6)
        let maxBoxWidthFromSpacing = max(minCenterSpacing - spacingGap, 0)
        let boxWidth = min(clampedBoxHeight * 1.8, maxBoxWidthFromSpacing)
        let activeSet = Set(activeStringNumbers)
        return ZStack {
            // Six individual translucent backgrounds for each answer box
            ForEach(0..<totalStrings, id: \.self) { index in
                let stringNumber = totalStrings - index
                let isActive = activeSet.contains(stringNumber)
                RoundedRectangle(cornerRadius: UIConstants.answerBoxRadius, style: .continuous)
                    .fill(Color.black.opacity(0.42))
                    .frame(width: boxWidth, height: clampedBoxHeight)
                    .opacity(isActive ? 1 : 0.0001)
                    .position(x: grooveCenters[index], y: centerY)
            }

            ForEach(0..<totalStrings, id: \.self) { index in
                let stringNumber = totalStrings - index
                let isActive = activeSet.contains(stringNumber)
                let displayedNoteText = revealedNoteTextByString?[stringNumber] ?? revealedNoteText
                let displayText = displayedNoteText.map(guitarNoteDisplayText)
                let noteIsAccidental = displayedNoteText.map(guitarNoteContainsAccidental) ?? false
                let shouldUseAccidentalStyle = noteIsAccidental
                let fillColor: Color = {
                    guard isActive else { return Color.clear }
                    if showFeedbackColors {
                        switch answerFeedback {
                        case .green: return Color.feedbackGreenFill.opacity(0.95)
                        case .red:   return Color.feedbackRedFill.opacity(0.95)
                        default: break
                        }
                    } else if answerFeedback == .red {
                        return Color.feedbackRedFill.opacity(0.95)
                    }
                    return shouldUseAccidentalStyle ? Color.black.opacity(0.95) : Color.white.opacity(0.92)
                }()
                let strokeColor: Color = {
                    guard isActive else { return .clear }
                    if showFeedbackColors {
                        switch answerFeedback {
                        case .green: return Color.feedbackGreenStroke.opacity(0.9)
                        case .red:   return Color.feedbackRedStroke.opacity(0.9)
                        default: break
                        }
                    } else if answerFeedback == .red {
                        return Color.feedbackRedStroke.opacity(0.9)
                    }
                    return shouldUseAccidentalStyle ? Color.white.opacity(0.86) : Color.black.opacity(0.72)
                }()

                RoundedRectangle(cornerRadius: UIConstants.answerBoxRadius, style: .continuous)
                    .fill(fillColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: UIConstants.answerBoxRadius, style: .continuous)
                            .stroke(strokeColor, lineWidth: 2)
                    )
                    .frame(width: boxWidth, height: clampedBoxHeight)
                    .overlay {
                        if isActive, let displayText, !displayText.isEmpty {
                            Text(displayText)
                                .font(.system(size: min(clampedBoxHeight * 0.72, 26), weight: .black, design: .monospaced))
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

// MARK: - Startup Sequence View
// Flashing CRT startup text shown in the dev console during the arm sequence.

struct StartupSequenceView: View {
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

// MARK: - BeginnerGameplayView UI subview methods
// These @ViewBuilder functions are pure rendering — they read state but never mutate it.
// Extracted from BeginnerGameplayView.swift (Step 1 of refactor).

extension BeginnerGameplayView {

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

    func beatPulseOverlay(centerX: CGFloat, centerY: CGFloat, isHidden: Bool) -> some View {
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

    func developerConsoleFrame(
        proxyWidth: CGFloat,
        topStatusCenterY: CGFloat,
        topStatusOuterWidth: CGFloat,
        topStatusOuterHeight: CGFloat
    ) -> some View {
        let currentTargetString = activeStringOrder[min(max(roundStringIndex, 0), activeStringOrder.count - 1)]
        let promptStrings = beginnerRuntime.currentPromptStrings.isEmpty ? [currentTargetString] : beginnerRuntime.currentPromptStrings
        let fretStatusLabel = "FRET \(beginnerRuntime.currentRound)"
        let stringStatusLabel = promptStrings.count > 1
            ? "STRINGS \(promptStrings.map(String.init).joined(separator: "+"))"
            : "STRING \(promptStrings[0])"
        let isGameplayStarted = !isCodeScreensaverMode
        let displayedFretStatusLabel = isGameplayStarted ? fretStatusLabel : ""
        let displayedStringStatusLabel: String = {
            if lessonStyle == .sequential { return "SEQUENTIAL MODE" }
            return isGameplayStarted ? stringStatusLabel : ""
        }()
        let roundStatusLabel = fretStatusLabel

        return DeveloperConsoleFrame(
            width: topStatusOuterWidth,
            height: topStatusOuterHeight,
            isScreensaverMode: isCodeScreensaverMode,
            layoutMode: layoutMode,
            roundTitle: roundStatusLabel,
            fretTitle: displayedFretStatusLabel,
            stringTitle: displayedStringStatusLabel,
            bankText: "$\(beginnerRuntime.displayedBankDollars)",
            scaleRepetitionText: beginnerRuntime.scaleRepetitionsRemaining >= Int.max / 2 ? "∞X" : "\(beginnerRuntime.scaleRepetitionsRemaining)X",
            promptText: developerPromptText,
            startupElapsed: startupSequenceElapsed,
            showStartupSequence: startupSequenceActivated,
            startupShowFullSequence: layoutMode != .beginner,
            startupArmedText: beginnerStartupArmedText,
            beginnerRoundStatusText: beginnerRoundStatusText,
            centeredStatusMessage: beginnerCenteredStatusMessage,
            centeredStatusColor: Color.green.opacity(0.98),
            currentRound: beginnerRuntime.currentRound,
            repetitionCountColor: getRepetitionCountColor(),
            walletColor: getWalletColor(),
            hideRoundLabel: false,
            pentatonicRevealComplete: beginnerRuntime.answerBoxReady || beginnerRuntime.pendingRewardStageAdvance,
            noteHighlightIndex: lessonStyle == .sequential ? sequentialNoteGenerator.sequenceProgressIndex : beginnerRuntime.scaleSequenceIndex,
            sequentialSlots: (layoutMode == .beginner && lessonStyle == .sequential && !sequentialNoteGenerator.currentNoteSequence.isEmpty)
                ? zip(sequentialNoteGenerator.currentNoteSequence, sequentialNoteGenerator.noteStringMap).map { (note: $0, stringNumber: $1) }
                : nil,
            sequentialRevealCount: min(beginnerRuntime.sequentialRevealCount, sequentialNoteGenerator.currentNoteSequence.count),
            sequentialAnsweredCount: sequentialNoteGenerator.sequenceProgressIndex,
            chordSlots: (layoutMode == .beginner && lessonStyle == .chord && !beginnerCurrentScaleNotes.isEmpty)
                ? zip(beginnerCurrentScaleNotes, chordNoteStringMap).map { (note: $0, stringNumber: $1) }
                : nil,
            chordRevealCount: min(beginnerRuntime.pentatonicRevealCount, beginnerCurrentScaleNotes.count),
            chordAnsweredCount: beginnerRuntime.scaleSequenceIndex,
            rewardNoteTextByString: beginnerRuntime.rewardNoteTextByString,
            consoleSkin: consoleSkin
        )
        .position(x: proxyWidth / 2, y: topStatusCenterY)
        .allowsHitTesting(false)
        .opacity(codenameNemoEnabled ? 0 : 1)
    }

    @ViewBuilder
    func maestroThumbOverlay(
        proxyWidth: CGFloat,
        buttonCenterY: CGFloat,
        thumbDiameter: CGFloat,
        leftThumbState: ThumbGlowState,
        rightThumbState: ThumbGlowState,
        dimOpacity: CGFloat
    ) -> some View {
        HStack(spacing: 28) {
            Button(action: { submitAnswer(.left) }) {
                ThumbButtonView(
                    diameter: thumbDiameter,
                    label: "",
                    state: leftThumbState
                )
            }
            .buttonStyle(.plain)
            .disabled(beginnerRuntime.isResolvingAnswer)
            .accessibilityLabel(A11y.Beginner.leftThumb)
            .accessibilityHint(A11y.Beginner.leftThumbHint)

            Button(action: { submitAnswer(.right) }) {
                ThumbButtonView(
                    diameter: thumbDiameter,
                    label: "",
                    state: rightThumbState
                )
            }
            .buttonStyle(.plain)
            .disabled(beginnerRuntime.isResolvingAnswer)
            .accessibilityLabel(A11y.Beginner.rightThumb)
            .accessibilityHint(A11y.Beginner.rightThumbHint)
        }
        .frame(maxWidth: .infinity)
        .position(x: proxyWidth / 2, y: buttonCenterY)
        .allowsHitTesting(showMaestroOverlays)
        .accessibilityHidden(!showMaestroOverlays)
        .opacity(codenameNemoEnabled ? 0 : (showMaestroOverlays ? dimOpacity : 0))
    }

    @ViewBuilder
    func transportButtonPanelOverlay(
        proxyWidth: CGFloat,
        transportCenterY: CGFloat,
        startupState: (text: String, color: Color, isVisible: Bool, phase: StartupSequenceView.Phase)
    ) -> some View {
        let startButtonShouldHighlight: Bool = startupStartButtonAttentionActive && (!startupSequenceActivated ? startupStartButtonBlinkOn : startupState.isVisible)
        HStack(spacing: 6) {
            Button("START") { handleStartButtonPress() }
                .frame(minWidth: 58, minHeight: UIConstants.controlPlateButtonHeight, maxHeight: UIConstants.controlPlateButtonHeight)
                .background(
                    RoundedRectangle(cornerRadius: UIConstants.controlPlateButtonRadius, style: .continuous)
                        .fill(startButtonShouldHighlight ? Color.green.opacity(0.9) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: UIConstants.controlPlateButtonRadius, style: .continuous)
                                .stroke(Color.black.opacity(0.34), lineWidth: 1.0)
                        )
                )
                .accessibilityLabel(A11y.Transport.start)
                .accessibilityHint(A11y.Transport.startHint)
            Button(isRoundPaused ? "RESUME" : "PAUSE") {
                if isRoundPaused { resumeRoundFromTransportStop(forceIfPaused: true) }
                else { handleRoundStopButton() }
            }
                .frame(minWidth: 58, minHeight: UIConstants.controlPlateButtonHeight, maxHeight: UIConstants.controlPlateButtonHeight)
                .disabled(!canPressStopButton && !isRoundPaused)
                .background(
                    RoundedRectangle(cornerRadius: UIConstants.controlPlateButtonRadius, style: .continuous)
                        .fill(isRoundPaused ? Color.orange.opacity(0.85) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: UIConstants.controlPlateButtonRadius, style: .continuous)
                                .stroke(Color.black.opacity(0.34), lineWidth: 1.0)
                        )
                )
                .accessibilityLabel(isRoundPaused ? A11y.Transport.resume : A11y.Transport.pause)
                .accessibilityHint(isRoundPaused ? A11y.Transport.resumeHint : A11y.Transport.pauseHint)
            Button("RESET") { handleRoundResetButton() }
                .frame(minWidth: 58, minHeight: UIConstants.controlPlateButtonHeight, maxHeight: UIConstants.controlPlateButtonHeight)
                .background(
                    RoundedRectangle(cornerRadius: UIConstants.controlPlateButtonRadius, style: .continuous)
                        .fill(beginnerRuntime.resetButtonPressed ? Color.green.opacity(0.8) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: UIConstants.controlPlateButtonRadius, style: .continuous)
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
        .position(x: proxyWidth / 2, y: transportCenterY - 22)
        .opacity(codenameNemoEnabled ? 0 : 1)
    }

    @ViewBuilder
    func beginnerButtonPanelOverlay(
        proxyWidth: CGFloat,
        proxyHeight: CGFloat,
        buttonCenterY: CGFloat,
        lowerScreenHeight: CGFloat,
        transportCenterY: CGFloat,
        dimOpacity: Double,
        startupState: (text: String, color: Color, isVisible: Bool, phase: StartupSequenceView.Phase)
    ) -> some View {
        let beginnerButtonDiameter: CGFloat = min(max(proxyWidth * 0.18, 66), 84) * 0.85
        let beginnerButtonSpacing: CGFloat = beginnerButtonDiameter * 1.62
        let row0Y: CGFloat = buttonCenterY - beginnerButtonSpacing
        let row1Y: CGFloat = buttonCenterY
        let row2Y: CGFloat = buttonCenterY + beginnerButtonSpacing
        let rowYs: [CGFloat] = [row0Y, row1Y, row2Y]
        let leftButtonX: CGFloat = proxyWidth * 0.2335
        let rightButtonX: CGFloat = proxyWidth * 0.7665
        let beginnerScreenHeight: CGFloat = lowerScreenHeight * 0.76 * 1.2
        let beginnerScreenWidth: CGFloat = beginnerScreenHeight * 1.6
        let noteScreenCenterYOffset: CGFloat = -beginnerButtonDiameter * 0.13
        let screenInset: CGFloat = beginnerButtonDiameter * 0.88
        let leftScreenX: CGFloat = leftButtonX + screenInset
        let rightScreenX: CGFloat = rightButtonX - screenInset
        let leftStrings: [Int] = [4, 5, 6]
        let rightStrings: [Int] = [3, 2, 1]
        ZStack {
            ForEach(Array(0..<3), id: \.self) { idx in
                let selectedString: Int = leftStrings[idx]
                let buttonNote: String = guitarNoteName(forString: leftStrings[idx], fret: max(beginnerRuntime.currentRound, 0), useFlats: beginnerUsesFlats)
                let displayButtonNote: String = guitarNoteDisplayText(buttonNote)
                let buttonIndex: Int = idx
                MiniTVFrame(
                    text: displayButtonNote,
                    width: beginnerScreenWidth,
                    height: beginnerScreenHeight,
                    fontScale: 1.0,
                    isDarkScreen: guitarNoteContainsAccidental(buttonNote),
                    consoleSkin: consoleSkin
                )
                .position(x: leftScreenX, y: rowYs[idx] + noteScreenCenterYOffset)

                Button(action: {
                    handleBeginnerConsoleButtonPress(selectedNote: buttonNote, selectedString: selectedString, buttonIndex: buttonIndex)
                }) {
                    ThumbButtonView(
                        diameter: beginnerButtonDiameter,
                        label: "",
                        state: beginnerButtonState(for: buttonIndex, startupPhase: startupState.phase, startupIsVisible: startupState.isVisible),
                        consoleSkin: consoleSkin
                    )
                }
                .buttonStyle(.plain)
                .position(x: leftButtonX, y: rowYs[idx])
                .accessibilityLabel(A11y.Beginner.consoleButton(note: buttonNote, stringNumber: selectedString))
                .accessibilityHint(A11y.Beginner.consoleButtonHint(note: buttonNote))
            }

            ForEach(Array(0..<3), id: \.self) { idx in
                let selectedString: Int = rightStrings[idx]
                let buttonNote: String = guitarNoteName(forString: rightStrings[idx], fret: max(beginnerRuntime.currentRound, 0), useFlats: beginnerUsesFlats)
                let displayButtonNote: String = guitarNoteDisplayText(buttonNote)
                let buttonIndex: Int = idx + 3
                MiniTVFrame(
                    text: displayButtonNote,
                    width: beginnerScreenWidth,
                    height: beginnerScreenHeight,
                    fontScale: 1.0,
                    isDarkScreen: guitarNoteContainsAccidental(buttonNote),
                    consoleSkin: consoleSkin
                )
                .position(x: rightScreenX, y: rowYs[idx] + noteScreenCenterYOffset)

                Button(action: {
                    handleBeginnerConsoleButtonPress(selectedNote: buttonNote, selectedString: selectedString, buttonIndex: buttonIndex)
                }) {
                    ThumbButtonView(
                        diameter: beginnerButtonDiameter,
                        label: "",
                        state: beginnerButtonState(for: buttonIndex, startupPhase: startupState.phase, startupIsVisible: startupState.isVisible),
                        consoleSkin: consoleSkin
                    )
                }
                .buttonStyle(.plain)
                .position(x: rightButtonX, y: rowYs[idx])
                .accessibilityLabel(A11y.Beginner.consoleButton(note: buttonNote, stringNumber: selectedString))
                .accessibilityHint(A11y.Beginner.consoleButtonHint(note: buttonNote))
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
                .shadow(color: Color.highlightBlue.opacity(0.95), radius: 12)
                .shadow(color: Color.white.opacity(0.45), radius: 5)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.75), lineWidth: 1)
                )
                .position(x: proxyWidth / 2, y: proxyHeight / 2)
                .opacity(beginnerRuntime.beatLightFlashOn ? 1 : 0)
                .animation(.easeOut(duration: 0.08), value: beginnerRuntime.beatLightFlashOn)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .allowsHitTesting(true)
        .opacity(codenameNemoEnabled ? 0 : dimOpacity)
        .accessibilityHidden(false)
    }

    func beginnerButtonState(for buttonIndex: Int, startupPhase: StartupSequenceView.Phase, startupIsVisible: Bool) -> ThumbGlowState {
        if let pressedIndex = beginnerPressedButtonIndex, pressedIndex == buttonIndex {
            return beginnerPressedButtonCorrect ? .green : .red
        }
        if isCodeScreensaverMode && startupPhase == .armed && startupIsVisible {
            return .green
        }
        return .neutral
    }
}
