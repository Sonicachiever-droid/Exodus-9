import Foundation

// MARK: - Beginner Game State
// Single observable model replacing BeginnerRuntimeState struct + 15+ @State bools.
// All game logic mutations go through BeginnerGameEngine; this is pure data.

@Observable
final class BeginnerGameState {

    // MARK: Phase & Round
    var currentPhaseNumber: Int = 1
    var currentRoundInPhase: Int = 1
    var correctAnswersAtCurrentFret: Int = 0
    var scaleRepetitionsRemaining: Int = 1
    var coursePhase: BeginnerCoursePhase = .round1Ascending

    // MARK: Unified Reveal System (one set of counters for all lesson styles)
    var revealCount: Int = 0
    var revealStartBeatBucket: Int? = nil
    var roundOneIntroActive: Bool = false
    var roundOneSequenceStartDate: Date? = nil
    var answerBoxReady: Bool = false

    // MARK: Reveal aliases (random & sequential share the unified counters)
    var randomRevealCount: Int {
        get { revealCount }
        set { revealCount = newValue }
    }
    var randomRevealStartBeatBucket: Int? {
        get { revealStartBeatBucket }
        set { revealStartBeatBucket = newValue }
    }
    var sequentialRevealCount: Int {
        get { revealCount }
        set { revealCount = newValue }
    }
    var sequentialRevealStartBeatBucket: Int? {
        get { revealStartBeatBucket }
        set { revealStartBeatBucket = newValue }
    }

    // MARK: Phase Announcements & Completion
    var phaseAnnouncementStartBeat: Double? = nil
    var phaseAnnouncementPhase: Int = 0   // 0=none,1=number,2=attributes,3=completed
    var phaseCompletedMessagePending: Bool = false
    var phaseCompletedMessageStartBeat: Double? = nil
    var completedPhaseNumber: Int = 0
    var pendingPhaseCompletedAutoAdvanceDate: Date? = nil
    var phaseTransitionPending: Bool = false
    var nextPhaseNumber: Int = 1

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

    // MARK: Celebration
    var celebrationFlashOn: Bool = false
    var celebrationNextFlashDate: Date? = nil

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

    // MARK: Computed helpers
    var isDescendingPhase: Bool { currentPhaseNumber % 2 == 0 }
    var isAscendingPhase: Bool  { currentPhaseNumber % 2 == 1 }

    // MARK: Reset to Phase 1

    func resetToPhaseOne() {
        currentPhaseNumber = 1
        currentRoundInPhase = 1
        correctAnswersAtCurrentFret = 0
        scaleRepetitionsRemaining = 1
        coursePhase = .round1Ascending
        clearReveal()
        clearPhaseMessaging()
        clearAutoPlay()
        clearReward()
    }

    func clearReveal() {
        revealCount = 0
        revealStartBeatBucket = nil
        roundOneIntroActive = false
        roundOneSequenceStartDate = nil
        answerBoxReady = false
        pentatonicRevealCount = 0
        revealBeatBucket = nil
        introStartBeatBucket = nil
        showRoundZeroIntroSequence = false
    }

    func clearPhaseMessaging() {
        phaseAnnouncementStartBeat = nil
        phaseCompletedMessagePending = false
        phaseCompletedMessageStartBeat = nil
        completedPhaseNumber = 0
        pendingPhaseCompletedAutoAdvanceDate = nil
        phaseTransitionPending = false
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
