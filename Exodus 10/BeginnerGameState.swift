import Foundation

// MARK: - Beginner Game State
// Single observable model replacing BeginnerRuntimeState struct + 15+ @State bools.
// All game logic mutations go through BeginnerGameEngine; this is pure data.

@Observable
final class BeginnerGameState {

    // MARK: Round
    var correctAnswersAtCurrentFret: Int = 0
    var scaleRepetitionsRemaining: Int = 1

    // MARK: Unified Reveal System (one set of counters for all lesson styles)
    var revealCount: Int = 0
    var revealStartBeatBucket: Int? = nil
    var roundOneIntroActive: Bool = false
    var roundOneSequenceStartDate: Date? = nil
    var answerBoxReady: Bool = false
    var pendingSequentialRepeatResetBeatPosition: Double? = nil
    var pendingSequentialRepeatDisplayText: String? = nil

    // MARK: Reveal aliases (sequential shares the unified counters)
    var sequentialRevealCount: Int {
        get { revealCount }
        set { revealCount = newValue }
    }
    var sequentialRevealStartBeatBucket: Int? {
        get { revealStartBeatBucket }
        set { revealStartBeatBucket = newValue }
    }

    // MARK: Round Shift
    var pendingRoundShiftBeatPosition: Double? = nil
    var pendingRewardStageAdvance: Bool = false
    var rewardTargetBeatPosition: Double? = nil
    var rewardSelectedString: Int? = nil

    // MARK: Autoplay
    var autoPlayEnabled: Bool = false
    var autoPlayNextDate: Date? = nil
    var isAutoPlayTriggered: Bool = false

    // MARK: Beat Light
    var beatLightFlashOn: Bool = false
    var beatLightLastProcessedBeat: Int? = nil
    var beatLightIntroMeasureSkipped: Bool = false

    // MARK: Answer / Reward Display
    var lastPickedNote: String? = nil
    var rewardNoteTextByString: [Int: String]? = nil
    var rewardScheduledStrings: [Int] = []
    var rewardScheduledMIDINotes: [Int] = []
    var rewardScheduledNoteTextByString: [Int: String] = [:]
    var rewardSustainMultiplier: Double = 3.0

    // MARK: Scale / Chord State (chord mode)
    var scaleSequenceIndex: Int = 0
    var scaleStageIndex: Int = 0
    var scaleCycleSemitoneOffset: Int = 0
    var pentatonicRevealCount: Int = 0
    var revealBeatBucket: Int? = nil        // chord-mode specific reveal bucket
    var introStartBeatBucket: Int? = nil
    var showRoundZeroIntroSequence: Bool = false

    // MARK: MIDI Stop
    var pendingMidiStopDate: Date? = nil

    // MARK: Note/fret navigation (moved from BeginnerGameplayView @State — Step 3)
    var currentRound: Int = 0
    var isDescendingPhase: Bool = false
    var currentFretStart: Int = 0
    var currentWindowRow: Int = 2
    var leftChoiceNote: String = ""
    var rightChoiceNote: String = ""
    var correctAnswerSide: AnswerSide = .left
    var currentCorrectNote: String = ""
    var currentQuestionIsAccidental: Bool = false
    var currentPromptStrings: [Int] = [1]
    var bankDollars: Int = 0
    var displayedBankDollars: Int = 0
    var isRoundArmed: Bool = true
    var transportStoppedForResume: Bool = false
    var isResolvingAnswer: Bool = false
    var activePickedStringNumbers: [Int] = [1]
    var answeredNotesByStringAtCurrentFret: [Int: String] = [:]
    var autoPlayLastStringByNote: [String: Int] = [:]
    var activeAnswerFeedback: ThumbGlowState? = nil

    // MARK: Beat timing (moved from BeginnerGameplayView @State — Step 2)
    var beatCountInRemaining: Int = 0
    var nextBeatTickDate: Date? = nil

    // MARK: Round reveal timing (moved from BeginnerGameplayView @State — Step 2)
    var roundRevealElapsedBeats: Double = 0
    var roundRevealLastTickDate: Date? = nil

    // MARK: Question box animation (moved from BeginnerGameplayView @State — Step 2)
    var questionBoxIntroProgress: CGFloat = 0

    // MARK: Streak meter (moved from BeginnerGameplayView @State — Step 2)
    var streakMeterLitColumns: Int = 0
    var streakMeterFailureActive: Bool = false
    var streakMeterFailureVisibleColumns: Int = 0

    // MARK: Last resolved note (moved from BeginnerGameplayView @State — Step 2)
    var lastResolvedCorrectNote: String? = nil
    var lastResolvedCorrectString: Int? = nil

    // MARK: Last prompted note (moved from BeginnerGameplayView @State — Step 2)
    var lastPromptedCorrectNote: String? = nil
    var lastPromptedStringHalf: AnswerSide? = nil
    var lastPromptedStringNumber: Int? = nil
    var recentPromptedCorrectNotes: [String] = []

    // MARK: Transport UI state (moved from BeginnerGameplayView @State — Step 2)
    var resetButtonPressed: Bool = false

    // MARK: Reset

    func reset() {
        correctAnswersAtCurrentFret = 0
        scaleRepetitionsRemaining = 1
        clearReveal()
        clearAutoPlay()
        clearReward()
    }

    func clearReveal() {
        revealCount = 0
        revealStartBeatBucket = nil
        roundOneIntroActive = false
        roundOneSequenceStartDate = nil
        answerBoxReady = false
        pendingSequentialRepeatResetBeatPosition = nil
        pendingSequentialRepeatDisplayText = nil
        pentatonicRevealCount = 0
        revealBeatBucket = nil
        introStartBeatBucket = nil
        showRoundZeroIntroSequence = false
    }

    func clearAutoPlay() {
        autoPlayNextDate = nil
    }

    func clearReward() {
        pendingRewardStageAdvance = false
        rewardTargetBeatPosition = nil
        rewardSelectedString = nil
        rewardNoteTextByString = nil
        rewardScheduledStrings = []
        rewardScheduledMIDINotes = []
        rewardScheduledNoteTextByString = [:]
        rewardSustainMultiplier = 3.0
        lastPickedNote = nil
    }
}
