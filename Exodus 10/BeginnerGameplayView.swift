import SwiftUI
import Combine
import AVFoundation

// MARK: - Types and components from extracted files
// Types.swift contains: GameplayMenuOption, RefretMode, GameplayModeVariant, AnswerSide, LayoutMode, BeginnerCoursePhase, BeginnerRoundZeroIntroDisplayPhase, HighlightWindowShape, FretMath, GuitarStringLayout, baselineNutTargetY, resolvedNeckTopY
// ViewComponents.swift contains: StringLineOverlay, MiniTVFrame, ThumbButtonView
// BeginnerSubviews.swift contains: WhiteNoteBoxOverlay, StartupSequenceView, + BeginnerGameplayView extension (fretIndicatorOverlay, beatPulseOverlay, developerConsoleFrame, maestroThumbOverlay, transportButtonPanelOverlay, beginnerButtonPanelOverlay, beginnerButtonState)
// DeveloperViews.swift contains: DeveloperCodeRunnerView, DeveloperConsoleFrame, DeveloperTVStreakMeterView


struct BeginnerGameplayView: View {
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
    var lessonStyle: LessonStyle { LessonStyle(rawValue: playLessonStyle) ?? .chord }
    @Binding var playProgression: String
    @Binding var walletDollars: Int
    @Binding var balanceDollars: Int
    let consoleSkin: ConsoleSkin
    @AppStorage("exodus10.runtime.directionLockActive") var directionLockActive: Bool = false

    @State var audioSettings = AudioSettings()
    @State var showAudioPage: Bool = false
    let layoutMode: LayoutMode = .beginner

    @Environment(\.displayScale) private var displayScale
    let totalFrets: Int = 20
    var maxFretOffset: Int { totalFrets }
    var minFretOffset: Int { -totalFrets }
    var modeVariant: GameplayModeVariant {
        if layoutMode == .beginner {
            return lessonStyle == .chord ? .chord : .freestyle
        }

        switch selectedMode {
        case .beat:
            return .beat
        case .chord:
            return .chord
        case .mixed:
            switch beginnerRuntime.currentRound % 3 {
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

    var isPhaseDescending: Bool {
        beginnerRuntime.isDescendingPhase
    }

    var showMaestroOverlays: Bool {
        layoutMode == .maestro
    }

    var isProgressionLowToHigh: Bool { playProgression == "lowToHigh" }

    var activeStringOrder: [Int] {
        let baseOrder: [Int] = {
            let base: [Int] = selectedMode == .oneHand ? [1, 2, 3, 4] : [1, 2, 3, 4, 5, 6]
            return (modeVariant == .freestyle && isProgressionLowToHigh) ? base.reversed() : base
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
    // chromaticSharps, chromaticFlats, openNoteByString — use module-level globals from GuitarHelpers.swift
    let codenameNemoEnabled: Bool = false
    private let scaleLengthInches: Double = 25.5
    private let debugGridRows: Int = 8
    private var maxWindowRow: Int { (debugGridRows - 1) * 2 } // half-step increments across rows
    // beginnerRuntime.currentFretStart, beginnerRuntime.currentWindowRow, beginnerRuntime.currentRound, beginnerRuntime.isDescendingPhase,
    // beginnerRuntime.leftChoiceNote, beginnerRuntime.rightChoiceNote, beginnerRuntime.correctAnswerSide, beginnerRuntime.currentCorrectNote,
    // beginnerRuntime.currentQuestionIsAccidental, beginnerRuntime.currentPromptStrings, beginnerRuntime.bankDollars, beginnerRuntime.displayedBankDollars,
    // beginnerRuntime.isRoundArmed, beginnerRuntime.transportStoppedForResume, beginnerRuntime.isResolvingAnswer,
    // beginnerRuntime.activePickedStringNumbers, beginnerRuntime.answeredNotesByStringAtCurrentFret,
    // beginnerRuntime.autoPlayLastStringByNote, beginnerRuntime.activeAnswerFeedback — moved to BeginnerGameState (Step 3)
    // (Step 2 vars also live in BeginnerGameState)
    @State var leftThumbState: ThumbGlowState = .neutral
    @State var rightThumbState: ThumbGlowState = .neutral
    @State var beginnerPressedButtonIndex: Int? = nil
    @State var beginnerPressedButtonCorrect: Bool = false
    @State var roundStringIndex: Int = 0

    // Chord system integration
    @StateObject private var chordGenerator = ChordGenerator()
    // Sequential style integration
    @StateObject var sequentialNoteGenerator = SequentialNoteGenerator()
    // Unified generator access — no more if/else chains at callsites
    var currentGenerator: any NoteSequenceGenerator {
        sequentialNoteGenerator
    }
    @State var introWindowBlack: Bool = true
    @State var introDidRun: Bool = false
    @State var isCodeScreensaverMode: Bool = true
    @State var startupSequenceStartDate: Date = .now
    @State var startupSequenceElapsed: TimeInterval = 0
    @State var startupSequenceActivated: Bool = false
    @State var assetToNutBottomDelta: CGFloat? = nil
    @State var questionBoxAssistActive: Bool = false
    @State var gameplayMenuExpanded: Bool = false
    @State var developerPromptText: String = ""
    @State var beatQuestionDeadline: Date? = nil
    @State var showFretboardGuide: Bool = false
    @State var isRoundPaused: Bool = false
    @State var isBackingTrackPlaying: Bool = false
    @State var isLaunchTransitionAnimating: Bool = false
    @State var launchTileScale: CGFloat = 1
    @State var launchTileOpacity: Double = 1
    @State var startupNeckVisualsHidden: Bool = false
    @State var startupStartButtonBlinkOn: Bool = false
    @State var startupStartButtonNextBlinkDate: Date? = nil
    @State var beatPulseActive: Bool = false
    @State var beginnerRuntime = BeginnerGameState()

    enum StartupSpeechPhase {
        case idle
        case pendingSystem
        case pendingPhase
        case pendingArmed
    }

    // BeginnerStageTemplate, BeginnerScaleStage, BeginnerRewardPolicyKey, BeginnerRewardPolicy
    // — moved to Types.swift (Step 5)

    @State var startupSpeechPhase: StartupSpeechPhase = .idle
    @State var availableBackingTracks: [BackingTrack] = []

    let gameplayAudioEngine = SpeechEngine()
    let guitarNoteEngine: GuitarNotePlaying = SharedAudioEngine.shared
    let midiEngine: BackingTrackPlaying = SharedAudioEngine.shared
    let audioEngineEnabled: Bool = false
    let speakBeatTicks: Bool = false
    let speakGameplayPrompts: Bool = false
    let beginnerScaleTemplates: [BeginnerStageTemplate] = [
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

    // beginnerChordSuffixDisplay, beginnerScaleStages, beginnerCurrentScaleStage, beginnerCurrentScaleNotes,
    // beginnerCurrentScaleTitle, chordNoteStringMap, beginnerCurrentBassSemitoneTarget,
    // beginnerRewardPolicies, beginnerPentatonicProgressText, shouldShowLegacyRoundZeroIntro,
    // getWalletColor, getRepetitionCountColor, beginnerRoundStatusText, beginnerCenteredStatusMessage,
    // beginnerCenteredStatusColor, beginnerRoundZeroIntroDisplayPhase, beginnerAcceptsGameplayAnswers,
    // playDirection, effectivePlayRepetitions, beginnerRoundTwoStartsDescending, beginnerLowerFretBoundary,
    // beginnerUpperFretBoundary, clampedBeginnerStartingFret, beginnerRoundOneStartingFret,
    // beginnerRoundTwoStartingFret, beginnerRoundOneStartsDescending, beginnerUsesFlats,
    // backingTrackShouldPlayInGameplay, startupStartButtonAttentionActive, canPressStopButton,
    // shouldLockPlayDirection, beginnerStartupArmedText
    // — moved to BeginnerGameplayLogic.swift (Step 5)
    init(
        onMenuSelection: ((GameplayMenuOption) -> Void)? = nil,
        selectedMode: RefretMode = .freestyle,
        beatVolume: Double = 0.8,
        stringVolume: Double = 0.8,
        playStartingFret: Binding<Int> = .constant(0),
        playRepetitions: Binding<Int> = .constant(5),
        playInfiniteRepetitions: Binding<Bool> = .constant(false),
        playDirectionRawValue: Binding<String> = .constant(LessonDirection.ascending.rawValue),
        playEnableHighFrets: Binding<Bool> = .constant(false),
        playLessonStyle: Binding<String> = .constant("chord"),
        playProgression: Binding<String> = .constant("highToLow"),
        walletDollars: Binding<Int> = .constant(0),
        balanceDollars: Binding<Int> = .constant(0),
        consoleSkin: ConsoleSkin = .classic
    ) {
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
            let lowerWhitePipingY = buttonBottomY + whitePipingGap - (gridRowHeight * GuitarConstants.gridRowHeightRatio)
            let transportCenterY = min(
                windowBottomY + max(gridRowHeight * 1.15, 24),
                upperWhitePipingY - max(gridRowHeight * 0.95, 20)
            )
            let whitePipingWidth = max(proxy.size.width - 7, 0)
            let noteChoiceY = upperWhitePipingY - (lowerScreenHeight / 2) - 2
            let windowTopY = holeCenterY - highlightHeight / 2
            let topStatusOuterWidth = highlightWidth
            let topStatusOuterHeight = max(min(gridRowHeight * 1.35, 120), 74)
            let topStatusBottomGap = max(gridRowHeight * GuitarConstants.gridRowHeightRatio, 10)
            let topStatusCenterY = (windowTopY - topStatusBottomGap) - (topStatusOuterHeight / 2)
            let sideWindowGap = max((proxy.size.width - highlightWidth) / 4, 18)
            let leftFretIndicatorX = (proxy.size.width / 2) - (highlightWidth / 2) - sideWindowGap
            let rightFretIndicatorX = (proxy.size.width / 2) + (highlightWidth / 2) + sideWindowGap
            let fretIndicatorText = "\(max(beginnerRuntime.currentRound, 0))"

            let unsignedN = abs(beginnerRuntime.currentFretStart)
            let activeMidpointIndex: Int = {
                if beginnerRuntime.currentFretStart > 0 {
                    return max(beginnerRuntime.currentFretStart - 1, 0)
                }
                return unsignedN
            }()
            let clampedN = min(activeMidpointIndex, fretRatios.count - 2)
            let topRatio = fretRatios[clampedN]
            let bottomRatio = fretRatios[clampedN + 1]
            let midRatio = (topRatio + bottomRatio) / 2.0
            let sign: CGFloat = beginnerRuntime.currentFretStart >= 0 ? 1.0 : -1.0
            let activeMidpoint = midRatio * neckHeight * sign
            
            let nutTargetY = baselineNutTargetY(highlightTopGridLineY: highlightTopGridLineY, gridRowHeight: gridRowHeight)
            let neckTopY = resolvedNeckTopY(
                currentFretStart: beginnerRuntime.currentFretStart,
                nutTargetY: nutTargetY,
                highlightCenterY: pipingCenterY,
                activeMidpoint: activeMidpoint
            )
            
            let neckOffsetY: CGFloat = {
                if beginnerRuntime.currentFretStart == 0 {
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

                if consoleSkin == .tweed {
                    TweedWindowView(
                        canvasSize: proxy.size,
                        highlightWidth: highlightWidth,
                        highlightHeight: highlightHeight,
                        highlightCenter: CGPoint(x: proxy.size.width / 2, y: orangeGreenUnitCenterY),
                        highlightCornerRadius: highlightCornerRadius
                    )
                    .allowsHitTesting(false)
                } else {
                    ElephantWindowView(
                        canvasSize: proxy.size,
                        highlightWidth: highlightWidth,
                        highlightHeight: highlightHeight,
                        highlightCenter: CGPoint(x: proxy.size.width / 2, y: orangeGreenUnitCenterY),
                        highlightCornerRadius: highlightCornerRadius
                    )
                    .allowsHitTesting(false)
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
                            RoundedRectangle(cornerRadius: UIConstants.answerBoxRadius, style: .continuous)
                                .fill(Color.black.opacity(0.42))
                                .frame(width: guideTileWidth, height: guideTileHeight)
                                .position(x: stringCenters[index], y: guideBoxCenterY)
                        }

                        ForEach(Array(fretboardStrings.enumerated()), id: \.offset) { index, stringNumber in
                            let note = guitarNoteName(forString: stringNumber, fret: max(beginnerRuntime.currentRound, 0), useFlats: beginnerUsesFlats)
                            let displayNote = guitarNoteDisplayText(note)
                            let noteIsAccidental = guitarNoteContainsAccidental(note)
                            let tileFill = noteIsAccidental ? Color.black.opacity(0.94) : Color.white.opacity(0.96)
                            let tileStroke = noteIsAccidental ? Color.white.opacity(0.7) : Color.black.opacity(0.68)
                            let textColor = noteIsAccidental ? Color.white.opacity(0.98) : Color.black.opacity(0.95)
                            let noteFontSize = min(guideBoxHeight * 0.44, 24)

                            RoundedRectangle(cornerRadius: guideBoxCornerRadius * 0.45, style: .continuous)
                                .fill(tileFill)
                                .overlay(
                                    RoundedRectangle(cornerRadius: guideBoxCornerRadius * 0.45, style: .continuous)
                                        .stroke(tileStroke, lineWidth: 1.2)
                                )
                                .frame(width: guideTileWidth, height: guideTileHeight)
                                .overlay {
                                    Text(displayNote)
                                        .font(.system(size: noteFontSize, weight: .black, design: .monospaced))
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

                developerConsoleFrame(
                    proxyWidth: proxy.size.width,
                    topStatusCenterY: topStatusCenterY,
                    topStatusOuterWidth: topStatusOuterWidth,
                    topStatusOuterHeight: topStatusOuterHeight
                )

                let introScale = max(beginnerRuntime.questionBoxIntroProgress, 0.001)
                let introOffsetY = (1 - beginnerRuntime.questionBoxIntroProgress) * ((proxy.size.height / 2) - topScreenY)
                let questionBoxOffsetY = (1 - beginnerRuntime.questionBoxIntroProgress) * ((proxy.size.height / 2) - orangeGreenUnitCenterY)
                let shouldShowQuestionUI = !isCodeScreensaverMode && !startupSequenceActivated && beginnerRuntime.questionBoxIntroProgress > 0.0
                let hasBeginnerSelectedNote = !(beginnerRuntime.lastPickedNote?.isEmpty ?? true)
                    || !(beginnerRuntime.rewardNoteTextByString?.isEmpty ?? true)
                let shouldShowWhiteAnswerBox = shouldShowQuestionUI && {
                    if layoutMode != .beginner { return true }
                    // Show answer box when note is selected, regardless of game state
                    if hasBeginnerSelectedNote && beginnerRuntime.answerBoxReady {
                        return true
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
                            hitTestingEnabled: false,
                            consoleSkin: consoleSkin
                        )
                        MiniTVFrame(
                            text: displayedFretStatusLabel,
                            width: screenBannerWidth,
                            height: screenBannerHeight,
                            fontScale: 0.82,
                            glowTint: questionBoxAssistActive ? .orange : nil,
                            hitTestingEnabled: false,
                            consoleSkin: consoleSkin
                        )
                    }
                    .scaleEffect(introScale)
                    .animation(.easeInOut(duration: 0.5), value: beginnerRuntime.questionBoxIntroProgress)
                    .offset(y: introOffsetY)
                    .frame(width: proxy.size.width, height: screenBannerHeight)
                    .position(x: proxy.size.width / 2, y: topScreenY)
                    .allowsHitTesting(showMaestroOverlays)
                    .accessibilityHidden(!showMaestroOverlays)
                    .opacity(codenameNemoEnabled ? 0 : (showMaestroOverlays ? initialGameplayDimOpacity * introScale : 0))

                    MiniTVFrame(text: guitarNoteDisplayText(beginnerRuntime.leftChoiceNote), width: lowerScreenWidth, height: lowerScreenHeight, fontScale: 1.0, consoleSkin: consoleSkin)
                        .position(x: leftAnswerCenterX, y: noteChoiceY)
                        .allowsHitTesting(false)
                        .accessibilityHidden(!showMaestroOverlays)
                        .opacity(codenameNemoEnabled ? 0 : (showMaestroOverlays ? introScale : 0))

                    MiniTVFrame(text: guitarNoteDisplayText(beginnerRuntime.rightChoiceNote), width: lowerScreenWidth, height: lowerScreenHeight, fontScale: 1.0, consoleSkin: consoleSkin)
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
                            activeStringNumbers: beginnerRuntime.activePickedStringNumbers,
                            answerFeedback: beginnerRuntime.activeAnswerFeedback,
                            revealedNoteText: layoutMode == .beginner
                                ? (hasBeginnerSelectedNote ? beginnerRuntime.lastPickedNote : nil)
                                : (beginnerRuntime.activeAnswerFeedback == .green ? beginnerRuntime.currentCorrectNote : nil),
                            revealedNoteTextByString: layoutMode == .beginner ? (beginnerRuntime.rewardNoteTextByString ?? beginnerRuntime.answeredNotesByStringAtCurrentFret) : nil,
                            revealedNoteTextColor: Color.black.opacity(0.96)
                        )
                        .allowsHitTesting(false)
                        .offset(y: questionBoxOffsetY)
                        .opacity(codenameNemoEnabled ? 0 : initialGameplayDimOpacity)
                    }
                }

                if consoleSkin != .tweed {
                    GoldHorizontalPipingLine(width: whitePipingWidth)
                        .position(x: proxy.size.width / 2, y: upperWhitePipingY)
                        .allowsHitTesting(false)
                        .opacity(codenameNemoEnabled ? 0 : (showMaestroOverlays ? 1 : 0))

                    GoldHorizontalPipingLine(width: whitePipingWidth)
                        .position(x: proxy.size.width / 2, y: lowerWhitePipingY)
                        .allowsHitTesting(false)
                        .opacity(codenameNemoEnabled ? 0 : (showMaestroOverlays ? 1 : 0))
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
                    },
                    consoleSkin: consoleSkin
                )
                    .frame(maxWidth: min((proxy.size.width - 24) * 0.88, 370))
                    .padding(.bottom, 12)
                    .opacity(codenameNemoEnabled ? 0 : 1)
            }
            .overlay(alignment: .topLeading) {
                // No AUTO button overlay
            }
            .overlay(alignment: .topLeading) {
                maestroThumbOverlay(
                    proxyWidth: proxy.size.width,
                    buttonCenterY: buttonCenterY,
                    thumbDiameter: thumbDiameter,
                    leftThumbState: effectiveLeftThumbState,
                    rightThumbState: effectiveRightThumbState,
                    dimOpacity: initialGameplayDimOpacity
                )
            }
            .overlay(alignment: .topLeading) {
                if layoutMode == .beginner {
                    beginnerButtonPanelOverlay(
                        proxyWidth: proxy.size.width,
                        proxyHeight: proxy.size.height,
                        buttonCenterY: buttonCenterY,
                        lowerScreenHeight: lowerScreenHeight,
                        transportCenterY: transportCenterY,
                        dimOpacity: initialGameplayDimOpacity,
                        startupState: startupState
                    )
                }
            }
            .overlay {
                transportButtonPanelOverlay(
                    proxyWidth: proxy.size.width,
                    transportCenterY: transportCenterY,
                    startupState: startupState
                )
            }
            .overlay {
                EmptyView()
            }
            .onAppear(perform: handleContentOnAppear)
            .onDisappear {
                midiEngine.stop()
            }
            .sheet(isPresented: $showAudioPage, onDismiss: handleAudioPageDismiss) {
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
            .onChange(of: beginnerRuntime.currentRound) { _, newValue in
                _ = newValue
                applyBeginnerBassTransposeForCurrentStage()
            }
            .onChange(of: playRepetitions) { _, _ in
                guard layoutMode == .beginner else { return }

                if beginnerRuntime.isRoundArmed || isRoundPaused {
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
                beginnerRuntime.autoPlayNextDate = revealReady ? nextOnAndThreeBeatDate(after: Date(), waitForDownbeat: true) : nil
            }
            .offset(y: globalContentShiftY)
        }
    }

    // shiftFretSpan, shiftWindow, nextThumbState, textWidth, handleStartupSpeech,
    // syncBackingTrackPlayback, postponeBeatDeadlineForAssist, showDeveloperPrompt, midiNoteValue
    // — moved to BeginnerGameplayLogic.swift (Step 5)
}

