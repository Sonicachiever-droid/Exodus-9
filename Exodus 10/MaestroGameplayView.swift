import SwiftUI
import Combine
import AVFoundation

// MaestroStartupSequenceView, RowOneIdentifierOverlay — moved to MaestroSubviews.swift





struct MaestroGameplayView: View {
    let onMenuSelection: ((GameplayMenuOption) -> Void)?
    let selectedMode: RefretMode
    var beatBPM: Int { audioSettings.startingBPM }
    let beatVolume: Double
    let stringVolume: Double
    @Binding var playStartingFret: Int
    @Binding var playRepetitions: Int
    @Binding var playInfiniteRepetitions: Bool
    @Binding var playDirectionRawValue: String
    @Binding var playEnableHighFrets: Bool
    @Binding var playLessonStyle: String
    @Binding var playProgression: String
    @Binding var walletDollars: Int
    @Binding var balanceDollars: Int
    let orientation: Orientation
    let consoleSkin: ConsoleSkin

    @Environment(\.displayScale) private var displayScale
    private let totalFrets: Int = 20
    var maxFretOffset: Int { totalFrets }
    var minFretOffset: Int { -totalFrets }

    var isPhaseDescending: Bool {
        LessonDirection(rawValue: playDirectionRawValue) == .descending
    }

    var isProgressionLowToHigh: Bool { playProgression == "lowToHigh" }

    var maestroUsesFlats: Bool { isPhaseDescending }

    var activeStringOrder: [Int] {
        let base: [Int] = selectedMode == .oneHand ? [1, 2, 3, 4] : [1, 2, 3, 4, 5, 6]
        return isProgressionLowToHigh ? base.reversed() : base
    }

    var modePayoutMultiplier: Double {
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
    // chromaticSharps, chromaticFlats, openNoteByString — use module-level globals from GuitarHelpers.swift
    let codenameNemoEnabled: Bool = false
    let scaleLengthInches: Double = 25.5
    let debugGridRows: Int = 8
    var maxWindowRow: Int { (debugGridRows - 1) * 2 } // half-step increments across rows
    @State var currentFretStart: Int = 0
    @State var currentWindowRow: Int = 2
    @State var leftThumbState: ThumbGlowState = .neutral
    @State var rightThumbState: ThumbGlowState = .neutral
    @State var currentRound: Int = 0
    @State var roundStringIndex: Int = 0
    @State var repetitionsRemainingAtFret: Int = 1
    @State var isDescendingPhase: Bool = false
    @State var leftChoiceNote: String = ""
    @State var rightChoiceNote: String = ""
    @State var activePickedStringNumbers: [Int] = [1]
    @State var answeredNotesByStringAtCurrentFret: [Int: String] = [:]
    @State var activeAnswerFeedback: ThumbGlowState? = nil
    @State var currentQuestionIsAccidental: Bool = false
    @State var introWindowBlack: Bool = true
    @State var introDidRun: Bool = false
    @State var isCodeScreensaverMode: Bool = true
    @State var cachedStringStatusLabel: String = ""
    @State var cachedFretStatusLabel: String = ""
    @State var bankDollars: Int = 0
    @State var displayedBankDollars: Int = 0
    @State var startupSequenceStartDate: Date = .now
    @State var startupSequenceElapsed: TimeInterval = 0
    @State var startupSequenceActivated: Bool = false
    @State var assetToNutBottomDelta: CGFloat? = nil
    @State var isAutoPlayTriggered: Bool = false
    @State var correctAnswerSide: AnswerSide = .left
    @State var isResolvingAnswer: Bool = false
    @State var gameplayMenuExpanded: Bool = false
    @State var maestroStartButtonBlinkOn: Bool = false
    @State var maestroStartButtonNextBlinkDate: Date? = nil
    @State var developerPromptText: String = ""
    @State var currentCorrectNote: String = ""
    @State var lastResolvedCorrectNote: String? = nil
    @State var lastResolvedCorrectString: Int? = nil
    @State var currentPromptStrings: [Int] = [1]
    @State var isRoundPaused: Bool = false
    @State var transportStoppedForResume: Bool = false
    @State var showFretboardGuide: Bool = false
    @State var isLaunchTransitionAnimating: Bool = false
    @State var launchTileScale: CGFloat = 1
    @State var launchTileOpacity: Double = 1
    @State var beatPulseActive: Bool = false
    @State var beatCountInRemaining: Int = 0
    @State var nextBeatTickDate: Date? = nil
    @State var beatLightFlashOn: Bool = false
    @State var beatLightLastProcessedBeat: Int? = nil
    @State var questionBoxPulsePhase: Bool = false
    @State var nextQuestionBoxPulseDate: Date? = nil
    @State var questionBoxIntroProgress: CGFloat = 0
    @State var autoPlayEnabled: Bool = false
    @State var autoPlayNextDate: Date? = nil
    @State var resetButtonPressed: Bool = false
    @State var streakMeterLitSegments: Int = 0
    @State var streakMeterFailureActive: Bool = false
    @State var streakMultiplier: Int = 1
    @State var streakMultiplierFlashText: String? = nil

    enum StartupSpeechPhase {
        case idle
        case pendingArmed
    }

    @State var startupSpeechPhase: StartupSpeechPhase = .idle
    @State var audioSettings = AudioSettings()
    @State var availableBackingTracks: [BackingTrack] = []
    @State var showAudioPage: Bool = false

    let audioEngine = SpeechEngine()
    let guitarNoteEngine: GuitarNotePlaying = SharedAudioEngine.shared
    let midiEngine: BackingTrackPlaying = SharedAudioEngine.shared
    let audioEngineEnabled: Bool = false
    let speakBeatTicks: Bool = false
    let speakGameplayPrompts: Bool = false

    init(
        onMenuSelection: ((GameplayMenuOption) -> Void)? = nil,
        selectedMode: RefretMode = .freestyle,
        beatVolume: Double = 0.8,
        stringVolume: Double = 0.8,
        playStartingFret: Binding<Int> = .constant(0),
        playRepetitions: Binding<Int> = .constant(0),
        playInfiniteRepetitions: Binding<Bool> = .constant(false),
        playDirectionRawValue: Binding<String> = .constant(""),
        playEnableHighFrets: Binding<Bool> = .constant(false),
        playLessonStyle: Binding<String> = .constant(""),
        playProgression: Binding<String> = .constant("highToLow"),
        walletDollars: Binding<Int> = .constant(0),
        balanceDollars: Binding<Int> = .constant(0),
        orientation: Orientation = .portrait,
        consoleSkin: ConsoleSkin = .classic
    ) {
        self.orientation = orientation
        self.onMenuSelection = onMenuSelection
        self.selectedMode = selectedMode
        self.beatVolume = beatVolume
        self.stringVolume = stringVolume
        self._playStartingFret = playStartingFret
        self._playRepetitions = playRepetitions
        self._playInfiniteRepetitions = playInfiniteRepetitions
        self._playDirectionRawValue = playDirectionRawValue
        self._playEnableHighFrets = playEnableHighFrets
        self._playLessonStyle = playLessonStyle
        self._playProgression = playProgression
        self._walletDollars = walletDollars
        self._balanceDollars = balanceDollars
        self.consoleSkin = consoleSkin
    }

    var body: some View {
        GeometryReader { proxy in
            if orientation == .landscape {
                landscapeBody(proxy: proxy)
            } else {
                portraitBody(proxy: proxy)
            }
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
        .sheet(isPresented: $showAudioPage, onDismiss: {
            if transportStoppedForResume {
                isRoundPaused = false
                transportStoppedForResume = false
                nextBeatTickDate = nil
                beatLightLastProcessedBeat = nil
                syncMaestroBackingTrack(allowResumeFromPause: true)
            }
        }) {
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
            autoPlayNextDate = nextOnAndThreeBeatDate(after: Date(), waitForDownbeat: true)
        }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { date in
            if isRoundPaused {
                return
            }

            if startupSequenceActivated {
                startupSequenceElapsed = max(date.timeIntervalSince(startupSequenceStartDate), 0)
                let startupState = MaestroStartupSequenceView.state(for: startupSequenceElapsed)
                handleStartupSpeech(for: startupState.phase)
                maestroStartButtonBlinkOn = false
                maestroStartButtonNextBlinkDate = nil
            } else if isCodeScreensaverMode {
                if maestroStartButtonNextBlinkDate == nil {
                    maestroStartButtonBlinkOn = true
                    maestroStartButtonNextBlinkDate = date.addingTimeInterval(0.45)
                } else if let nextBlink = maestroStartButtonNextBlinkDate, date >= nextBlink {
                    maestroStartButtonBlinkOn.toggle()
                    maestroStartButtonNextBlinkDate = date.addingTimeInterval(0.45)
                }
            } else {
                maestroStartButtonBlinkOn = false
                maestroStartButtonNextBlinkDate = nil
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

            if !isCodeScreensaverMode, midiEngine.isPlaying {
                let currentBeat = midiEngine.currentBeatPosition()
                let currentBeatBucket = Int(floor(currentBeat))

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

            let shouldPulseQuestionBox = !isCodeScreensaverMode
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
    }

    // MARK: - Portrait Neck Layer (Stage 1 extraction; portrait-authoritative neck/window/screensaver/fretboard-guide)
    // Identical to the inline block previously in portraitBody. Computes F1–F5 from `size` so the
    // same view tree can be reused (and, in a later stage, rotated) without duplicating geometry math.
    @ViewBuilder
    private func portraitNeckLayer(size: CGSize, centerScreensaverOnWindow: Bool = false, cutoutOffsetY: CGFloat = 0, matchBackgroundTexture: Bool = false, showWindowOverlay: Bool = true) -> some View {
        let padding: CGFloat = 24
        let neckWidth = (size.width - padding * 2) * 0.8
        let fretRatios = FretMath.fretPositionRatios(totalFrets: totalFrets, scaleLength: scaleLengthInches)
        let visibleFrets = min(totalFrets, 5)
        let visibleFretIndex = min(visibleFrets, fretRatios.count - 1)
        let visibleRatio = max(fretRatios[visibleFretIndex], 0.05)
        let visibleClipHeight = size.height * 0.96
        let unclippedHeight = visibleClipHeight / visibleRatio
        let minimumNeckHeight = size.height * 1.35
        let neckHeight = max(unclippedHeight, minimumNeckHeight)
        let nutHeight = max(neckHeight * 0.02, 18)
        let nutVisualHeight = nutHeight * 0.4
        let debugGridRows = 8
        let gridRowHeight = size.height / CGFloat(debugGridRows)
        let highlightHeight = 2 * gridRowHeight
        let lockedWindowTopRowIndex: CGFloat = 1.0
        let highlightTopGridLineY = lockedWindowTopRowIndex * gridRowHeight

        let scale = displayScale

        let highlightCenterYSnapped: CGFloat = {
            let raw = highlightTopGridLineY + highlightHeight / 2
            return (raw * scale).rounded() / scale
        }()
        let viewingWindowShiftY: CGFloat = gridRowHeight * 0.5
        let pipingCenterY = highlightCenterYSnapped + viewingWindowShiftY

        let orangeGreenUnitCenterY = pipingCenterY - (gridRowHeight * 0.5)
        let highlightAvailableWidth = max(size.width - padding * 2, 0)
        let highlightExtraWidth = max(highlightAvailableWidth - neckWidth, 0)
        let highlightWidth = neckWidth + highlightExtraWidth / 2
        let highlightCornerRadius = min(24, highlightWidth * 0.08)
        let windowBottomY = highlightCenterYSnapped + highlightHeight / 2
        let topStatusOuterHeight = max(min(gridRowHeight * 1.35, 120), 74)

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
                let raw = neckTopY - size.height / 2 + neckHeight / 2
                return (raw * scale).rounded() / scale
            } else {
                let raw = pipingCenterY - activeMidpoint - size.height / 2 + neckHeight / 2
                return (raw * scale).rounded() / scale
            }
        }()

        let manualBlueAdjustment: CGFloat = -gridRowHeight * 0.5
        let finalNeckOffsetY = neckOffsetY + manualBlueAdjustment
        let neckVisualOffsetAdjustment = finalNeckOffsetY - neckOffsetY
        let nutBottomY = neckTopY + neckVisualOffsetAdjustment + (nutVisualHeight * GuitarConstants.nutHeightOffset)
        let stringStopInset = max(1.0, 2.0 / max(scale, 1.0))
        let stringTopY = nutBottomY + stringStopInset

        HStack {
            Spacer()
            ZStack {
                ZStack(alignment: .top) {
                    ZStack {
                        if consoleSkin == .tweed {
                            MapleSegmentedBackground(
                                fretRatios: fretRatios,
                                cornerRadius: 18
                            )
                        } else {
                            RosewoodSegmentedBackground(
                                fretRatios: fretRatios,
                                cornerRadius: 18
                            )
                        }
                        BindingLayer()
                        FretWireLayer(fretRatios: fretRatios)
                        FretMarkerLayer(fretRatios: fretRatios)
                    }
                    .frame(width: neckWidth, height: neckHeight)

                    NutLayer(width: neckWidth * GuitarConstants.nutWidthRatio, height: nutVisualHeight)
                        .frame(width: neckWidth * GuitarConstants.nutWidthRatio, height: nutVisualHeight)
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
            .position(x: size.width / 2, y: pipingCenterY + cutoutOffsetY)
            .allowsHitTesting(false)
            .opacity(introWindowBlack ? 1 : 0)

        if showWindowOverlay {
            if consoleSkin == .tweed {
                TweedWindowView(
                    canvasSize: size,
                    highlightWidth: highlightWidth,
                    highlightHeight: highlightHeight,
                    highlightCenter: CGPoint(x: size.width / 2, y: (centerScreensaverOnWindow ? pipingCenterY : orangeGreenUnitCenterY) + cutoutOffsetY),
                    highlightCornerRadius: highlightCornerRadius,
                    textureBrightness: matchBackgroundTexture ? 0.08 : 0.12,
                    textureOverlayOpacity: matchBackgroundTexture ? 0.18 : 0.2,
                    textureBleed: matchBackgroundTexture ? 48 : 36
                )
                .allowsHitTesting(false)
            } else {
                ElephantWindowView(
                    canvasSize: size,
                    highlightWidth: highlightWidth,
                    highlightHeight: highlightHeight,
                    highlightCenter: CGPoint(x: size.width / 2, y: (centerScreensaverOnWindow ? pipingCenterY : orangeGreenUnitCenterY) + cutoutOffsetY),
                    highlightCornerRadius: highlightCornerRadius,
                    textureBrightness: matchBackgroundTexture ? 0.08 : 0.12,
                    textureOverlayOpacity: matchBackgroundTexture ? 0.18 : 0.2,
                    textureBleed: matchBackgroundTexture ? 48 : 36
                )
                .allowsHitTesting(false)
            }
        }

        if isCodeScreensaverMode {
            ZStack {
                if consoleSkin == .tweed {
                    Image("Refret tweed logo")
                        .resizable()
                        .scaledToFill()
                        .scaleEffect(x: 1.15, y: 1.0, anchor: .center)
                        .frame(width: highlightWidth, height: highlightHeight)
                        .clipped()
                        .clipShape(HighlightWindowShape(cornerRadius: highlightCornerRadius))

                    HighlightWindowChromeBorder(
                        width: highlightWidth,
                        height: highlightHeight,
                        cornerRadius: highlightCornerRadius
                    )
                } else {
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
            }
            .scaleEffect(isLaunchTransitionAnimating ? launchTileScale : 1)
            .opacity(isLaunchTransitionAnimating ? launchTileOpacity : 1)
            .position(x: size.width / 2, y: (centerScreensaverOnWindow ? pipingCenterY : orangeGreenUnitCenterY) + cutoutOffsetY)
            .allowsHitTesting(false)
        }

        if showFretboardGuide && !isCodeScreensaverMode {
            let guideBoxHeight = topStatusOuterHeight * 0.5
            let guideBoxCenterY = windowBottomY - (guideBoxHeight / 2) - 4
            let stringCenters = GuitarStringLayout.stringCenters(containerWidth: size.width, neckWidth: neckWidth)
            let centerSpacings = (1..<stringCenters.count).map { stringCenters[$0] - stringCenters[$0 - 1] }
            let minCenterSpacing = centerSpacings.min() ?? 60
            let spacingGap = max(minCenterSpacing * GuitarConstants.stringGapMultiplier, 6)
            let maxBoxWidthFromSpacing = max(minCenterSpacing - spacingGap, 0)
            let boxWidth = min(guideBoxHeight * 1.8, maxBoxWidthFromSpacing)
            let fretboardStrings = (0..<GuitarStringLayout.totalStrings).map { GuitarStringLayout.highestStringNumber - $0 }
            ZStack {
                // Six individual translucent backgrounds for each note box
                ForEach(Array(fretboardStrings.enumerated()), id: \.offset) { index, _ in
                    RoundedRectangle(cornerRadius: UIConstants.answerBoxRadius, style: .continuous)
                        .fill(Color.black.opacity(0.42))
                        .frame(width: boxWidth, height: guideBoxHeight)
                        .position(x: stringCenters[index], y: guideBoxCenterY)
                }

                ForEach(Array(fretboardStrings.enumerated()), id: \.offset) { index, stringNumber in
                    let note: String = noteName(forString: stringNumber, fret: max(currentRound, 0), useFlats: maestroUsesFlats)
                    let displayNote = guitarNoteDisplayText(note)
                    let isAccidental: Bool = guitarNoteContainsAccidental(note)
                    let fillColor: Color = isAccidental ? Color.black.opacity(0.95) : Color.white.opacity(0.92)
                    let strokeColor: Color = isAccidental ? Color.white.opacity(0.86) : Color.black.opacity(0.72)
                    let textColor: Color = isAccidental ? Color.white.opacity(0.96) : Color.black
                    let textSize = min(guideBoxHeight * 0.78, 28)
                    RoundedRectangle(cornerRadius: UIConstants.answerBoxRadius, style: .continuous)
                        .fill(fillColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: UIConstants.answerBoxRadius, style: .continuous)
                                .stroke(strokeColor, lineWidth: 2)
                        )
                        .overlay(
                            Text(displayNote)
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
    }

    @ViewBuilder
    private func portraitBody(proxy: GeometryProxy) -> some View {
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
            let _ = "FRET \(currentRound)"
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
            let lowerWhitePipingY = buttonBottomY + whitePipingGap - (gridRowHeight * GuitarConstants.gridRowHeightRatio)
            let whitePipingWidth = max(proxy.size.width - 7, 0)
            let noteChoiceY = upperWhitePipingY - (lowerScreenHeight / 2) - 14
            let developerOverlaysEnabled: Bool = false
            let windowTopY = holeCenterY - highlightHeight / 2
            let topStatusOuterWidth = highlightWidth
            let topStatusOuterHeight = max(min(gridRowHeight * 1.35, 120), 74)
            let topStatusBottomGap = max(gridRowHeight * GuitarConstants.gridRowHeightRatio, 10)
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
            let nutBottomY = neckTopY + neckVisualOffsetAdjustment + (nutVisualHeight * GuitarConstants.nutHeightOffset)
            let stringStopInset = max(1.0, 2.0 / max(scale, 1.0))
            let _ = nutBottomY + stringStopInset
            let calibratedAssetToNutDelta = assetToNutBottomDelta ?? 0
            let _ = (nutBottomY + calibratedAssetToNutDelta) - rowOneBottomLineY
            let startupState: (text: String, color: Color, isVisible: Bool, phase: MaestroStartupSequenceView.Phase) = {
                guard isCodeScreensaverMode else {
                    return ("", .clear, false, .armed)
                }
                guard startupSequenceActivated else {
                    return ("", .clear, false, .armed)
                }
                return MaestroStartupSequenceView.state(for: startupSequenceElapsed)
            }()
            let screensaverThumbState: ThumbGlowState = {
                guard startupState.isVisible else { return .neutral }
                return .green
            }()
            let effectiveLeftThumbState = isCodeScreensaverMode ? screensaverThumbState : leftThumbState
            let effectiveRightThumbState = isCodeScreensaverMode ? screensaverThumbState : rightThumbState
            let startButtonBlinkOn = isCodeScreensaverMode && (startupSequenceActivated ? startupState.isVisible : maestroStartButtonBlinkOn)
            let initialGameplayDimOpacity: CGFloat = (isCodeScreensaverMode && !startupSequenceActivated) ? 0.42 : 1.0
            let sideWindowGap = max((proxy.size.width - highlightWidth) / 4, 18)
            let leftFretIndicatorX = (proxy.size.width / 2) - (highlightWidth / 2) - sideWindowGap
            let rightFretIndicatorX = (proxy.size.width / 2) + (highlightWidth / 2) + sideWindowGap
            let fretIndicatorText = "\(max(currentRound, 0))"



            ZStack {
                if consoleSkin == .tweed {
                    FullScreenTweedBackground()
                        .ignoresSafeArea()
                    // Black fill so the window hole reveals a dark background, not more tweed
                    RoundedRectangle(cornerRadius: highlightCornerRadius, style: .continuous)
                        .fill(Color.black)
                        .frame(width: highlightWidth, height: highlightHeight)
                        .position(x: proxy.size.width / 2, y: orangeGreenUnitCenterY)
                        .allowsHitTesting(false)
                } else {
                    FullScreenElephantBackground()
                        .ignoresSafeArea()
                }

                portraitNeckLayer(size: proxy.size)

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
                    layoutMode: .maestro,
                    roundTitle: "",
                    fretTitle: "",
                    stringTitle: "",
                    bankText: "$\(displayedBankDollars)",
                    scaleRepetitionText: repetitionsRemainingAtFret >= Int.max / 2 ? "∞X" : "\(repetitionsRemainingAtFret)X",
                    promptText: "",
                    startupElapsed: startupSequenceElapsed,
                    showStartupSequence: startupSequenceActivated,
                    startupShowFullSequence: false,
                    startupArmedText: "Memorization Sequence Armed",
                    beginnerRoundStatusText: nil,
                    centeredStatusMessage: nil,
                    centeredStatusColor: .clear,
                    currentRound: currentRound,
                    repetitionCountColor: .white,
                    walletColor: .green,
                    hideRoundLabel: false,
                    pentatonicRevealComplete: false,
                    noteHighlightIndex: nil,
                    sequentialSlots: nil,
                    sequentialRevealCount: 0,
                    sequentialAnsweredCount: 0,
                    chordSlots: nil,
                    chordRevealCount: 0,
                    chordAnsweredCount: 0,
                    rewardNoteTextByString: nil,
                    consoleSkin: consoleSkin,
                    streakMeterLitSegments: isCodeScreensaverMode ? nil : streakMeterLitSegments,
                    streakMeterFailureActive: streakMeterFailureActive,
                    streakMultiplierFlashText: streakMultiplierFlashText
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
                            hitTestingEnabled: false,
                            consoleSkin: consoleSkin
                        )
                        MiniTVFrame(
                            text: displayedFretStatusLabel,
                            width: screenBannerWidth,
                            height: screenBannerHeight,
                            fontScale: 0.82,
                            hitTestingEnabled: false,
                            consoleSkin: consoleSkin
                        )
                    }
                    .scaleEffect(introScale)
                    .animation(.easeInOut(duration: 0.5), value: questionBoxIntroProgress)
                    .offset(y: introOffsetY)
                    .frame(width: proxy.size.width, height: screenBannerHeight)
                    .position(x: proxy.size.width / 2, y: topScreenY)
                    .opacity(codenameNemoEnabled ? 0 : initialGameplayDimOpacity * introScale)

                    // Blue beat light (center)
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
                        .overlay(Circle().stroke(Color.white.opacity(0.75), lineWidth: 1))
                        .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                        .opacity(beatLightFlashOn ? 1 : 0)
                        .animation(.easeOut(duration: 0.08), value: beatLightFlashOn)
                        .allowsHitTesting(false)

                    MiniTVFrame(text: guitarNoteDisplayText(leftChoiceNote), width: lowerScreenWidth, height: lowerScreenHeight, fontScale: 1.0, consoleSkin: consoleSkin)
                        .position(x: leftAnswerCenterX, y: noteChoiceY)
                        .allowsHitTesting(false)
                        .accessibilityHidden(false)
                        .opacity(codenameNemoEnabled ? 0 : introScale)

                    MiniTVFrame(text: guitarNoteDisplayText(rightChoiceNote), width: lowerScreenWidth, height: lowerScreenHeight, fontScale: 1.0, consoleSkin: consoleSkin)
                        .position(x: rightAnswerCenterX, y: noteChoiceY)
                        .allowsHitTesting(false)
                        .accessibilityHidden(false)
                        .opacity(codenameNemoEnabled ? 0 : introScale)

                    WhiteNoteBoxOverlay(
                        centerY: orangeGreenUnitCenterY,
                        availableSize: proxy.size,
                        boxHeight: gridRowHeight * 0.9,
                        neckWidth: neckWidth,
                        activeStringNumbers: activePickedStringNumbers,
                        answerFeedback: activeAnswerFeedback,
                        showFeedbackColors: false,
                        revealedNoteText: activeAnswerFeedback == .green ? currentCorrectNote : nil,
                        revealedNoteTextByString: answeredNotesByStringAtCurrentFret,
                        revealedNoteTextColor: Color.black.opacity(0.96)
                    )
                    .allowsHitTesting(false)
                    .offset(y: questionBoxOffsetY)
                    .opacity(codenameNemoEnabled ? 0 : initialGameplayDimOpacity)
                }

                if consoleSkin != .tweed {
                    GoldHorizontalPipingLine(width: whitePipingWidth)
                        .position(x: proxy.size.width / 2, y: upperWhitePipingY)
                        .allowsHitTesting(false)
                        .opacity(codenameNemoEnabled ? 0 : 1)

                    GoldHorizontalPipingLine(width: whitePipingWidth)
                        .position(x: proxy.size.width / 2, y: lowerWhitePipingY)
                        .allowsHitTesting(false)
                        .opacity(codenameNemoEnabled ? 0 : 1)
                }

                if consoleSkin == .tweed {
                    WhitePipingBorder(bottomInset: 0)
                        .allowsHitTesting(false)
                        .offset(y: -globalContentShiftY)
                        .zIndex(100)
                } else {
                    GoldPipingBorder(bottomInset: 0)
                        .allowsHitTesting(false)
                        .offset(y: -globalContentShiftY)
                        .zIndex(100)
                }

            }
            .overlay {
                debugGridOverlay(size: proxy.size, columns: debugGridColumns, rows: debugGridRows)
                    .allowsHitTesting(false)
                    .opacity(developerOverlaysEnabled ? 0.8 : 0)
            }
            .overlay {
                maestroTransportButtonOverlay(
                    proxyWidth: proxy.size.width,
                    proxyHeight: proxy.size.height,
                    lowerWhitePipingY: lowerWhitePipingY,
                    startButtonBlinkOn: startButtonBlinkOn
                )
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
                    },
                    consoleSkin: consoleSkin
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
                            state: effectiveLeftThumbState,
                            consoleSkin: consoleSkin
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(A11y.Maestro.leftThumb)
                    .accessibilityHint(A11y.Maestro.leftThumbHint)

                    Button(action: { submitAnswer(.right) }) {
                        ThumbButtonView(
                            diameter: thumbDiameter,
                            label: "",
                            state: effectiveRightThumbState,
                            consoleSkin: consoleSkin
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(A11y.Maestro.rightThumb)
                    .accessibilityHint(A11y.Maestro.rightThumbHint)
                }
                .frame(maxWidth: .infinity)
                .position(x: proxy.size.width / 2, y: buttonCenterY)
                .opacity(codenameNemoEnabled ? 0 : initialGameplayDimOpacity)
            }
            .offset(y: globalContentShiftY)
    }

    // MARK: - Landscape Body (Exodus 11 layout + portrait fret behavior)
    @ViewBuilder
    private func landscapeBody(proxy: GeometryProxy) -> some View {
        // ── Exodus 11 dimensions: short side = portraitWidth, long side = portraitHeight ──
        let padding: CGFloat = 24
        let portraitWidth = proxy.size.height   // short side
        let portraitHeight = proxy.size.width   // long side
        let fretRatios = FretMath.fretPositionRatios(totalFrets: totalFrets, scaleLength: scaleLengthInches)
        let visibleFrets = min(totalFrets, 5)
        let visibleFretIndex = min(visibleFrets, fretRatios.count - 1)
        let visibleRatio = max(fretRatios[visibleFretIndex], 0.05)
        let gridRowHeight = portraitHeight / 8.0
        let neckWidth = (portraitWidth - padding * 2) * 0.8
        let highlightHeight = 2 * gridRowHeight
        let visibleClipHeight = proxy.size.width * 0.96
        let unclippedHeight = visibleClipHeight / visibleRatio
        let minimumNeckHeight = proxy.size.width * 1.35
        let neckHeight = max(unclippedHeight, minimumNeckHeight)
        let nutHeight = max(neckHeight * 0.02, 18)
        let nutVisualHeight = nutHeight * 0.4
        let highlightAvailableWidth = max(proxy.size.height - 48, 0)
        let highlightExtraWidth = max(highlightAvailableWidth - neckWidth, 0)
        let highlightWidth = neckWidth + highlightExtraWidth / 2
        let highlightCornerRadius = min(24, highlightWidth * 0.08)
        let screenCenterY = proxy.size.height / 2
        let screenCenterX = proxy.size.width / 2

        let scale = displayScale

        // ── Portrait fret math adapted to screen-centered window ──
        // In landscape the window is centered on screen, so derive grid positions from that
        let highlightTopGridLineY = screenCenterY - highlightHeight / 2
        let highlightCenterYSnapped: CGFloat = {
            let raw = highlightTopGridLineY + highlightHeight / 2
            return (raw * scale).rounded() / scale
        }()
        let viewingWindowShiftY: CGFloat = gridRowHeight * 0.5
        let pipingCenterY = highlightCenterYSnapped + viewingWindowShiftY

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

        // Portrait helper functions — feed them the landscape-centered values
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
        let nutBottomY = neckTopY + neckVisualOffsetAdjustment + (nutVisualHeight * GuitarConstants.nutHeightOffset)
        let stringStopInset = max(1.0, 2.0 / max(scale, 1.0))
        let _ = nutBottomY + stringStopInset

        // Startup/screensaver state
        let startupState: (text: String, color: Color, isVisible: Bool, phase: MaestroStartupSequenceView.Phase) = {
            guard isCodeScreensaverMode else { return ("", .clear, false, .armed) }
            guard startupSequenceActivated else { return ("", .clear, false, .armed) }
            return MaestroStartupSequenceView.state(for: startupSequenceElapsed)
        }()
        let screensaverThumbState: ThumbGlowState = {
            guard startupState.isVisible else { return .neutral }
            return .green
        }()
        let effectiveLeftThumbState = isCodeScreensaverMode ? screensaverThumbState : leftThumbState
        let effectiveRightThumbState = isCodeScreensaverMode ? screensaverThumbState : rightThumbState
        let startButtonBlinkOn = isCodeScreensaverMode && (startupSequenceActivated ? startupState.isVisible : maestroStartButtonBlinkOn)
        let initialGameplayDimOpacity: CGFloat = (isCodeScreensaverMode && !startupSequenceActivated) ? 0.42 : 1.0

        // ── Exodus 11 element positions ──
        // Console above window
        let consoleHeightOld: CGFloat = 74
        let windowHalfH = proxy.size.height * 0.28
        let consoleBottomGapOld: CGFloat = 10
        let rawConsoleCenterYOld = screenCenterY - windowHalfH - consoleBottomGapOld - consoleHeightOld / 2
        let consoleCenterYOld = max(rawConsoleCenterYOld, consoleHeightOld / 2 + 8)
        let consoleTopEdge = consoleCenterYOld - consoleHeightOld / 2
        let neckWindowTopY = screenCenterY - highlightHeight / 2
        let consoleBottomGap: CGFloat = 4
        let consoleHeight = neckWindowTopY - consoleTopEdge - consoleBottomGap
        let consoleCenterY = consoleTopEdge + consoleHeight / 2

        // Transport bar below window
        let windowHalfHBelow = proxy.size.height * 0.26
        let windowBottomY = screenCenterY + windowHalfHBelow
        let transportScale: CGFloat = 0.8
        let transportHeight: CGFloat = 40 * transportScale
        let transportGap: CGFloat = 6
        let transportCenterY = windowBottomY + transportGap + transportHeight / 2

        // Thumb buttons in side gaps
        let thumbDiameter = min(proxy.size.width, proxy.size.height) * 0.336
        let leftGapCenter = (screenCenterX - highlightWidth / 2) / 2
        let rightGapCenter = screenCenterX + highlightWidth / 2 + leftGapCenter

        // Mini TV note choice screens
        let miniTVHeight: CGFloat = max(min(thumbDiameter * 0.52 * 1.75, 91), 77)
        let miniTVWidth: CGFloat = miniTVHeight * 1.6
        let vRowH = proxy.size.height / 40.0
        let miniTVCenterY = 8.0 * vRowH

        // Fret indicators centered between button inner edge and window piping
        let windowLeftEdge = screenCenterX - highlightWidth / 2
        let windowRightEdge = screenCenterX + highlightWidth / 2
        let leftThumbInnerEdge = leftGapCenter + thumbDiameter / 2
        let rightThumbInnerEdge = rightGapCenter - thumbDiameter / 2
        let fretOffsetFromWindow: CGFloat = 6
        let leftFretIndicatorX = (windowLeftEdge + leftThumbInnerEdge) / 2 - fretOffsetFromWindow
        let rightFretIndicatorX = (windowRightEdge + rightThumbInnerEdge) / 2 + fretOffsetFromWindow
        let fretIndicatorText = "\(max(currentRound, 0))"

        let shouldShowQuestionUI = !isCodeScreensaverMode && !startupSequenceActivated && questionBoxIntroProgress > 0.0

        ZStack {
            if consoleSkin == .tweed {
                // Layer 1: plain tweed background (no cutout) — behind the neck
                FullScreenTweedBackground()
                    .ignoresSafeArea()

                // Layer 2: black fill at the window position — behind the neck,
                // provides the dark interior when the neck doesn't fill the window.
                RoundedRectangle(cornerRadius: highlightCornerRadius, style: .continuous)
                    .fill(Color.black)
                    .frame(width: highlightWidth, height: highlightHeight)
                    .position(x: screenCenterX, y: screenCenterY)
                    .allowsHitTesting(false)
            } else {
                FullScreenElephantBackground()
                    .ignoresSafeArea()
            }

            // Layer 3: neck/fretboard layer (no TweedWindowView for tweed in landscape)
            ZStack {
                portraitNeckLayer(size: CGSize(width: proxy.size.height, height: proxy.size.width), centerScreensaverOnWindow: true, cutoutOffsetY: -gridRowHeight * 0.5, matchBackgroundTexture: true, showWindowOverlay: consoleSkin != .tweed)
            }
            .frame(width: proxy.size.height, height: proxy.size.width)
            .offset(y: proxy.size.width * 0.1875 + gridRowHeight * 0.5)
            .frame(width: proxy.size.width, height: proxy.size.height)

            // Layer 4 (tweed only): tweed-with-hole sits ABOVE the neck, covering any
            // neck content that bleeds outside the window. Uses the same ignoresSafeArea
            // GeometryReader as Layer 1 so the texture is pixel-identical — no seam.
            if consoleSkin == .tweed {
                FullScreenTweedBackground(
                    windowCutout: (
                        center: CGPoint(x: screenCenterX, y: screenCenterY),
                        width: highlightWidth,
                        height: highlightHeight,
                        cornerRadius: highlightCornerRadius
                    ),
                    safeAreaInsets: proxy.safeAreaInsets
                )
                .ignoresSafeArea()

                HighlightWindowChromeBorder(
                    width: highlightWidth,
                    height: highlightHeight,
                    cornerRadius: highlightCornerRadius
                )
                .position(x: screenCenterX, y: screenCenterY)
                .allowsHitTesting(false)
            }

            // Fret indicators (left/right of window)
            fretIndicatorOverlay(
                leftX: leftFretIndicatorX,
                rightX: rightFretIndicatorX,
                centerY: screenCenterY,
                text: fretIndicatorText,
                isHidden: isCodeScreensaverMode
            )

            // Developer console above neck window
            DeveloperConsoleFrame(
                width: highlightWidth,
                height: consoleHeight,
                isScreensaverMode: isCodeScreensaverMode,
                layoutMode: .maestro,
                roundTitle: "",
                fretTitle: "",
                stringTitle: "",
                bankText: "$\(displayedBankDollars)",
                scaleRepetitionText: repetitionsRemainingAtFret >= Int.max / 2 ? "∞X" : "\(repetitionsRemainingAtFret)X",
                promptText: "",
                startupElapsed: startupSequenceElapsed,
                showStartupSequence: startupSequenceActivated,
                startupShowFullSequence: false,
                startupArmedText: "Memorization Sequence Armed",
                beginnerRoundStatusText: nil,
                centeredStatusMessage: nil,
                centeredStatusColor: .clear,
                currentRound: currentRound,
                repetitionCountColor: .white,
                walletColor: .green,
                hideRoundLabel: false,
                pentatonicRevealComplete: false,
                noteHighlightIndex: nil,
                sequentialSlots: nil,
                sequentialRevealCount: 0,
                sequentialAnsweredCount: 0,
                chordSlots: nil,
                chordRevealCount: 0,
                chordAnsweredCount: 0,
                rewardNoteTextByString: nil,
                consoleSkin: consoleSkin,
                streakMeterLitSegments: isCodeScreensaverMode ? nil : streakMeterLitSegments,
                streakMeterFailureActive: streakMeterFailureActive,
                streakMultiplierFlashText: streakMultiplierFlashText
            )
            .position(x: screenCenterX, y: consoleCenterY)
            .allowsHitTesting(false)

            // Note choice MiniTVs and blue beat light
            if shouldShowQuestionUI {
                MiniTVFrame(
                    text: guitarNoteDisplayText(leftChoiceNote),
                    width: miniTVWidth,
                    height: miniTVHeight,
                    fontScale: 1.0,
                    isDarkScreen: guitarNoteContainsAccidental(leftChoiceNote),
                    consoleSkin: consoleSkin
                )
                .position(x: leftGapCenter, y: miniTVCenterY)
                .allowsHitTesting(false)

                MiniTVFrame(
                    text: guitarNoteDisplayText(rightChoiceNote),
                    width: miniTVWidth,
                    height: miniTVHeight,
                    fontScale: 1.0,
                    isDarkScreen: guitarNoteContainsAccidental(rightChoiceNote),
                    consoleSkin: consoleSkin
                )
                .position(x: rightGapCenter, y: miniTVCenterY)
                .allowsHitTesting(false)

                // Blue beat light (center)
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
                    .overlay(Circle().stroke(Color.white.opacity(0.75), lineWidth: 1))
                    .position(x: screenCenterX, y: screenCenterY)
                    .opacity(beatLightFlashOn ? 1 : 0)
                    .animation(.easeOut(duration: 0.08), value: beatLightFlashOn)
                    .allowsHitTesting(false)

                // White note boxes in the window
                WhiteNoteBoxOverlay(
                    centerY: screenCenterY - gridRowHeight * 0.5 + gridRowHeight * 0.5,
                    availableSize: proxy.size,
                    boxHeight: gridRowHeight * 0.9,
                    neckWidth: neckWidth,
                    activeStringNumbers: activePickedStringNumbers,
                    answerFeedback: activeAnswerFeedback,
                    showFeedbackColors: false,
                    revealedNoteText: activeAnswerFeedback == .green ? currentCorrectNote : nil,
                    revealedNoteTextByString: answeredNotesByStringAtCurrentFret,
                    revealedNoteTextColor: Color.black.opacity(0.96)
                )
                .allowsHitTesting(false)
                .opacity(initialGameplayDimOpacity)
            }

            // Thumb buttons
            Button(action: { submitAnswer(.left) }) {
                ThumbButtonView(diameter: thumbDiameter, label: "", state: effectiveLeftThumbState, consoleSkin: consoleSkin)
            }
            .buttonStyle(.plain)
            .position(x: leftGapCenter, y: screenCenterY)
            .opacity(initialGameplayDimOpacity)
            .accessibilityLabel(A11y.Maestro.leftThumb)
            .accessibilityHint(A11y.Maestro.leftThumbHint)

            Button(action: { submitAnswer(.right) }) {
                ThumbButtonView(diameter: thumbDiameter, label: "", state: effectiveRightThumbState, consoleSkin: consoleSkin)
            }
            .buttonStyle(.plain)
            .position(x: rightGapCenter, y: screenCenterY)
            .opacity(initialGameplayDimOpacity)
            .accessibilityLabel(A11y.Maestro.rightThumb)
            .accessibilityHint(A11y.Maestro.rightThumbHint)

            // Gold perimeter
            if consoleSkin == .tweed {
                WhitePipingBorder(bottomInset: 0)
                    .allowsHitTesting(false)
            } else {
                GoldPipingBorder(bottomInset: 0)
                    .allowsHitTesting(false)
            }
        }
        .overlay {
            // Transport bar below neck window
            HStack(spacing: 6) {
                Button("START") { handleMaestroStartButton() }
                    .frame(minWidth: UIConstants.transportButtonMinWidth, minHeight: UIConstants.transportButtonHeight, maxHeight: UIConstants.transportButtonHeight)
                    .background(transportButtonBackground(fill: startButtonBlinkOn ? Color.green.opacity(0.9) : Color.clear))
                    .accessibilityLabel(A11y.Transport.start)
                    .accessibilityHint(A11y.Transport.startHint)
                Button(isRoundPaused ? "RESUME" : "PAUSE") {
                    if isRoundPaused { handleMaestroStartButton() }
                    else { handleMaestroStopButton() }
                }
                    .frame(minWidth: UIConstants.transportButtonMinWidth, minHeight: UIConstants.transportButtonHeight, maxHeight: UIConstants.transportButtonHeight)
                    .disabled(isCodeScreensaverMode && !isRoundPaused)
                    .background(transportButtonBackground(fill: isRoundPaused ? Color.orange.opacity(0.85) : Color.clear))
                    .accessibilityLabel(isRoundPaused ? A11y.Transport.resume : A11y.Transport.pause)
                    .accessibilityHint(isRoundPaused ? A11y.Transport.resumeHint : A11y.Transport.pauseHint)
                Button("RESET") { handleMaestroResetButton() }
                    .frame(minWidth: UIConstants.transportButtonMinWidth, minHeight: UIConstants.transportButtonHeight, maxHeight: UIConstants.transportButtonHeight)
                    .accessibilityLabel(A11y.Transport.reset)
                    .accessibilityHint(A11y.Transport.resetHint)
                    .background(transportButtonBackground(fill: resetButtonPressed ? Color.green.opacity(0.8) : Color.clear))
            }
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundStyle(Color.black.opacity(0.92))
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LinearGradient(
                        colors: consoleSkin == .tweed
                            ? [.white, Color(red: 0.90, green: 0.90, blue: 0.90), .chromeDark, Color(red: 0.65, green: 0.65, blue: 0.65)]
                            : [.goldLight, .goldMid, .goldDark, .goldMidtone],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.black.opacity(0.26), lineWidth: 1.2))
            )
            .frame(width: highlightWidth * 0.72, height: transportHeight)
            .position(x: screenCenterX, y: transportCenterY)
        }
        .overlay(alignment: .bottom) {
            GameplayControlPlateShell(
                isMenuExpanded: gameplayMenuExpanded,
                isStartupInputLockActive: false,
                isAutoplayActive: autoPlayEnabled,
                onAutoplay: { autoPlayEnabled.toggle() },
                onFretboard: { handleFretboardButtonPress() },
                onToggleMenu: {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        gameplayMenuExpanded.toggle()
                    }
                },
                onSelectMenuOption: { option in handleGameplayMenuSelection(option) },
                consoleSkin: consoleSkin
            )
            .scaleEffect(0.8, anchor: .bottom)
            .frame(maxWidth: min((proxy.size.width - 24) * 0.88, 370))
            .padding(.bottom, 0)
        }
    }

}


#Preview {
    MaestroGameplayView()
}