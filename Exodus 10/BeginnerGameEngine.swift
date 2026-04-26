import SwiftUI

// MARK: - Beginner Game Engine
// All game logic lives here. BeginnerGameplayView only handles layout and timer.

@Observable
final class BeginnerGameEngine {

    // MARK: - State & Generators
    var state = BeginnerGameState()
    let randomGenerator    = RandomNoteGenerator()
    let sequentialGenerator = SequentialNoteGenerator()

    // MARK: - View-facing display state
    var currentFret: Int = 0
    var isDescendingPhase: Bool = false
    var isRoundArmed: Bool = true
    var isRoundPaused: Bool = false
    var isScreensaverMode: Bool = true
    var startupSequenceActivated: Bool = false
    var startupSequenceStartDate: Date = .now
    var startupSequenceElapsed: TimeInterval = 0
    var questionBoxIntroProgress: CGFloat = 0
    var isLaunchTransitionAnimating: Bool = false
    var launchTileScale: CGFloat = 1
    var launchTileOpacity: CGFloat = 1
    var pressedButtonIndex: Int? = nil
    var pressedButtonCorrect: Bool = false
    var beatPosition: Double = 0          // roundRevealElapsedBeats
    var beatPositionLastTickDate: Date? = nil
    var transportStoppedForResume: Bool = false

    // MARK: - Bindings (set by view from parent)
    var lessonStyle: LessonStyle = .sequential
    var bpm: Int = 120
    var useFlats: Bool = false
    var playRepetitions: Int = 1
    var startingFret: Int = 0

    // MARK: - Current Generator (unified access)
    var currentGenerator: any NoteSequenceGenerator {
        switch lessonStyle {
        case .random:     return randomGenerator
        case .sequential: return sequentialGenerator
        case .chord:      return sequentialGenerator // chord handled separately
        }
    }

    // MARK: - Computed display helpers

    var revealedNotesText: String {
        guard lessonStyle == .random || lessonStyle == .sequential else { return "" }
        let count = min(state.revealCount, GameConstants.maxRevealCount)
        return currentGenerator.currentNoteSequence.prefix(count).joined(separator: " ")
    }

    var armedText: String {
        if state.currentPhaseNumber > 1 {
            return "PHASE \(state.currentPhaseNumber) ARMED"
        }
        return "ARMED"
    }

    var phaseCompletedText: String? {
        guard state.phaseCompletedMessagePending else { return nil }
        return "PHASE \(state.completedPhaseNumber)\nCOMPLETED"
    }

    var phaseAnnouncementActive: Bool {
        state.phaseAnnouncementStartBeat != nil
    }

    // MARK: - Timer Tick (called every 0.1s from the view)

    func tick(date: Date, midiEngine: SimpleMIDIEngine) {
        updateStartupSequence(date: date)
        updatePhaseCompletedAutoAdvance(date: date, midiEngine: midiEngine)
        updateMidiStopIfNeeded(date: date, midiEngine: midiEngine)

        guard !isRoundArmed, !isRoundPaused else {
            state.beatLightFlashOn = false
            beatPositionLastTickDate = nil
            return
        }

        // Advance beat position
        if beatPositionLastTickDate == nil {
            beatPositionLastTickDate = date
        } else if let last = beatPositionLastTickDate {
            let delta = max(date.timeIntervalSince(last), 0)
            let beatsPerSecond = Double(max(bpm, GameConstants.minBPM)) / 60.0
            beatPosition += delta * beatsPerSecond
            beatPositionLastTickDate = date
        }

        updatePhaseAnnouncement(date: date)
        updateRevealProgress()
        handleAutoPlay(currentDate: date)
        handlePendingRoundShift(midiEngine: midiEngine)
        updateBeatLight(midiEngine: midiEngine, date: date)
    }

    // MARK: - Startup Sequence

    private func updateStartupSequence(date: Date) {
        guard startupSequenceActivated else { return }
        startupSequenceElapsed = max(date.timeIntervalSince(startupSequenceStartDate), 0)
    }

    // MARK: - Phase Completed Auto-Advance

    private func updatePhaseCompletedAutoAdvance(date: Date, midiEngine: SimpleMIDIEngine) {
        guard let advanceDate = state.pendingPhaseCompletedAutoAdvanceDate,
              date >= advanceDate else { return }
        state.pendingPhaseCompletedAutoAdvanceDate = nil
        state.phaseCompletedMessagePending = false
        state.phaseCompletedMessageStartBeat = nil
        advanceToNextPhaseArmedState(midiEngine: midiEngine)
    }

    private func updateMidiStopIfNeeded(date: Date, midiEngine: SimpleMIDIEngine) {
        guard let stopDate = state.pendingMidiStopDate, date >= stopDate else { return }
        state.pendingMidiStopDate = nil
        midiEngine.stop()
    }

    // MARK: - Phase Announcement (runs for 8 beats after START)

    private func updatePhaseAnnouncement(date: Date) {
        guard let startBeat = state.phaseAnnouncementStartBeat else { return }
        let elapsed = beatPosition - startBeat
        guard elapsed >= GameConstants.phaseAnnouncementBeats else { return }

        state.phaseAnnouncementStartBeat = nil
        // After announcement: start reveal
        state.roundOneIntroActive = true
        state.roundOneSequenceStartDate = date
        let bucket = Int(floor(beatPosition))
        state.revealStartBeatBucket = bucket
        state.revealCount = 0
    }

    // MARK: - Unified Reveal Progress (all lesson styles)

    func updateRevealProgress() {
        guard lessonStyle == .sequential || lessonStyle == .random else { return }
        guard !isScreensaverMode, !startupSequenceActivated else { return }
        guard state.roundOneIntroActive else { return }

        let currentBucket = Int(floor(beatPosition))
        if state.revealStartBeatBucket == nil {
            state.revealStartBeatBucket = currentBucket
        }
        let startBucket = state.revealStartBeatBucket ?? currentBucket
        let elapsed = max(currentBucket - startBucket, 0)
        let newCount = min(elapsed + 1, GameConstants.maxRevealCount)

        if newCount != state.revealCount {
            state.revealCount = newCount
        }
        if newCount >= GameConstants.maxRevealCount {
            state.answerBoxReady = true
        }
        // Unlock autoplay one beat after the 6th note appears
        if elapsed >= GameConstants.maxRevealCount {
            state.roundOneIntroActive = false
            state.roundOneSequenceStartDate = nil
        }
    }

    // MARK: - Autoplay

    func handleAutoPlay(currentDate: Date) {
        guard state.autoPlayEnabled,
              !isScreensaverMode,
              !startupSequenceActivated,
              !isRoundArmed,
              state.pendingRoundShiftBeatPosition == nil,
              lessonStyle == .random || lessonStyle == .sequential
        else {
            state.autoPlayNextDate = nil
            return
        }
        guard state.currentPhaseNumber >= GameConstants.minPhase,
              state.currentPhaseNumber <= GameConstants.maxPhase else {
            state.autoPlayNextDate = nil
            return
        }
        guard state.revealCount >= GameConstants.maxRevealCount else {
            state.autoPlayNextDate = nil
            return
        }
        // Direct elapsed-beats gate: wait until revealGateBeats after reveal started
        let currentBucket = Int(floor(beatPosition))
        let startBucket = state.revealStartBeatBucket ?? currentBucket
        let elapsed = currentBucket - startBucket
        guard elapsed >= GameConstants.revealGateBeats else {
            state.autoPlayNextDate = nil
            return
        }
        guard !currentGenerator.isSequenceComplete() else {
            state.autoPlayNextDate = nil
            return
        }
        guard let nextString = currentGenerator.expectedString,
              currentGenerator.sequenceProgressIndex < currentGenerator.currentNoteSequence.count else {
            state.autoPlayNextDate = nil
            return
        }
        let nextNote = currentGenerator.currentNoteSequence[currentGenerator.sequenceProgressIndex]

        if state.autoPlayNextDate == nil {
            state.autoPlayNextDate = currentDate.addingTimeInterval(GameConstants.autoPlayInterval)
            return
        }
        guard let nextDate = state.autoPlayNextDate, currentDate >= nextDate else { return }

        // Correct button index: left col strings 4-6 → idx 0-2; right col strings 1-3 → idx 3-5
        let buttonIndex = nextString >= 4 ? (nextString - 4) : (6 - nextString)
        state.isAutoPlayTriggered = true
        handleButtonPress(note: nextNote, string: nextString, buttonIndex: buttonIndex)
        state.isAutoPlayTriggered = false
        state.autoPlayNextDate = currentDate.addingTimeInterval(GameConstants.autoPlayInterval)
    }

    // MARK: - Button Press (unified for manual + autoplay)

    func handleButtonPress(note: String, string: Int, buttonIndex: Int) {
        guard !isRoundArmed else { handleRoundStart(); return }

        let canAdvance = !state.pendingRewardStageAdvance && !state.roundOneIntroActive
        guard canAdvance else { return }
        guard lessonStyle == .random || lessonStyle == .sequential else { return }
        guard !currentGenerator.isSequenceComplete() else { return }
        guard currentGenerator.isValidAnswer(note: note, string: string) else { return }

        // Correct — flash button green
        pressedButtonIndex = buttonIndex
        pressedButtonCorrect = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            self?.pressedButtonIndex = nil
            self?.pressedButtonCorrect = false
        }

        currentGenerator.advanceSequence()

        if currentGenerator.isSequenceComplete() {
            if state.scaleRepetitionsRemaining <= 1 {
                if state.pendingRoundShiftBeatPosition == nil {
                    state.pendingRoundShiftBeatPosition = beatPosition + GameConstants.roundShiftDelayBeats
                }
            } else {
                state.scaleRepetitionsRemaining -= 1
                resetGeneratorForRepetition()
            }
        }
    }

    private func resetGeneratorForRepetition() {
        let fret = max(currentFret, 0)
        let lowToHigh = state.currentPhaseNumber % 2 == 1
        currentGenerator.resetForNewFret()
        currentGenerator.generateNoteSequence(for: fret, useFlats: useFlats, lowToHigh: lowToHigh)
        state.revealCount = 0
        state.revealStartBeatBucket = nil
        state.roundOneIntroActive = true
        state.roundOneSequenceStartDate = Date()
        state.answerBoxReady = false
    }

    // MARK: - Round Shift (advance to next fret)

    func handlePendingRoundShift(midiEngine: SimpleMIDIEngine) {
        guard lessonStyle == .random || lessonStyle == .sequential,
              let targetBeat = state.pendingRoundShiftBeatPosition else { return }
        guard beatPosition >= targetBeat else { return }

        state.pendingRoundShiftBeatPosition = nil
        state.lastPickedNote = nil
        state.rewardNoteTextByString = nil
        state.answerBoxReady = false
        state.scaleRepetitionsRemaining = playRepetitions

        let fret = max(currentFret, 0)
        let lowToHigh = state.currentPhaseNumber % 2 == 1
        currentGenerator.resetForNewFret()
        currentGenerator.generateNoteSequence(for: fret, useFlats: useFlats, lowToHigh: lowToHigh)
        state.revealCount = 0
        state.revealStartBeatBucket = nil
        state.roundOneIntroActive = true
        state.roundOneSequenceStartDate = Date()

        // Advance fret
        let upperBoundary = 12
        if !isDescendingPhase {
            if currentFret < upperBoundary {
                currentFret += 1
                state.currentRoundInPhase += 1
            } else {
                handlePhaseCompletion(midiEngine: midiEngine)
                return
            }
        } else {
            if currentFret > 0 {
                currentFret -= 1
                state.currentRoundInPhase += 1
            } else {
                handlePhaseCompletion(midiEngine: midiEngine)
                return
            }
        }

        // Re-generate for new fret
        currentGenerator.generateNoteSequence(for: max(currentFret, 0), useFlats: useFlats, lowToHigh: lowToHigh)
    }

    // MARK: - Phase Completion

    func handlePhaseCompletion(midiEngine: SimpleMIDIEngine) {
        if state.currentPhaseNumber >= GameConstants.maxPhase {
            state.coursePhase = .round1Celebration
            state.celebrationFlashOn = true
            state.celebrationNextFlashDate = .now.addingTimeInterval(0.32)
            return
        }

        state.completedPhaseNumber = state.currentPhaseNumber
        state.phaseCompletedMessagePending = true
        state.phaseCompletedMessageStartBeat = beatPosition
        state.lastPickedNote = nil
        state.rewardNoteTextByString = nil
        state.answerBoxReady = false
        state.autoPlayNextDate = nil

        let secPer3Beats = 3.0 * 60.0 / Double(max(bpm, GameConstants.minBPM))
        let secPer4Beats = 4.0 * 60.0 / Double(max(bpm, GameConstants.minBPM))
        state.pendingMidiStopDate = Date().addingTimeInterval(secPer3Beats)
        state.pendingPhaseCompletedAutoAdvanceDate = Date().addingTimeInterval(secPer4Beats)
        isRoundArmed = true
    }

    // MARK: - Advance to Next Phase Armed State

    func advanceToNextPhaseArmedState(midiEngine: SimpleMIDIEngine) {
        let nextPhase = state.currentPhaseNumber + 1
        state.currentPhaseNumber = nextPhase
        state.currentRoundInPhase = 1
        state.correctAnswersAtCurrentFret = 0
        state.scaleRepetitionsRemaining = playRepetitions

        let descending = [2, 4, 6, 8].contains(nextPhase)
        currentFret = descending ? 12 : 0
        isDescendingPhase = descending

        let lowToHigh = nextPhase % 2 == 1
        currentGenerator.resetForNewFret()
        currentGenerator.generateNoteSequence(for: currentFret, useFlats: useFlats, lowToHigh: lowToHigh)
        state.revealCount = 0
        state.revealStartBeatBucket = nil

        beatPosition = 0
        beatPositionLastTickDate = nil
        isRoundArmed = true
        isScreensaverMode = true
        startupSequenceActivated = true
        startupSequenceStartDate = .now
        startupSequenceElapsed = 0
        questionBoxIntroProgress = 0
        midiEngine.stop()
    }

    // MARK: - Start Game / Round Start

    func handleRoundStart() {
        guard !isLaunchTransitionAnimating else { return }
        guard isRoundArmed else { return }

        // Fast-path: if phase completed message is showing, skip to next armed state
        if state.phaseCompletedMessagePending {
            state.pendingPhaseCompletedAutoAdvanceDate = nil
            state.phaseCompletedMessagePending = false
            state.phaseCompletedMessageStartBeat = nil
            // advanceToNextPhaseArmedState called by parent with midiEngine reference
            return
        }

        // Transition from screensaver to gameplay
        if isScreensaverMode {
            isLaunchTransitionAnimating = true
            launchTileScale = 1
            launchTileOpacity = 1
            // View handles the animation; calls startRoundAfterLaunch() after 0.4725s
            return
        }

        startRound()
    }

    func startRoundAfterLaunch() {
        isScreensaverMode = false
        startupSequenceActivated = false
        startupSequenceElapsed = 0
        isLaunchTransitionAnimating = false
        launchTileScale = 1
        launchTileOpacity = 1
        questionBoxIntroProgress = 1
        startRound()
    }

    private func startRound() {
        state.coursePhase = .round1Ascending
        isScreensaverMode = false
        startupSequenceActivated = false
        startupSequenceElapsed = 0
        questionBoxIntroProgress = 1
        isRoundPaused = false
        transportStoppedForResume = false
        isRoundArmed = false
        beatPosition = 0
        beatPositionLastTickDate = nil

        // Reset reveal for active style
        let fret = max(currentFret, 0)
        let lowToHigh = state.currentPhaseNumber % 2 == 1

        if lessonStyle == .random || lessonStyle == .sequential {
            currentGenerator.generateNoteSequence(for: fret, useFlats: useFlats, lowToHigh: lowToHigh)
            state.revealCount = 0
            state.revealStartBeatBucket = nil
            state.answerBoxReady = false

            // Phase 1: announcement runs first → roundOneIntroActive set after 8 beats
            // Phases 2+: no announcement → set intro active immediately
            if state.currentPhaseNumber > 1 {
                state.roundOneIntroActive = true
                state.roundOneSequenceStartDate = Date()
            } else {
                state.roundOneIntroActive = false
            }
        }

        // Trigger phase announcement for sequential/random phase 1
        if (lessonStyle == .sequential || lessonStyle == .random) && state.currentPhaseNumber == 1 {
            state.phaseAnnouncementStartBeat = beatPosition
        }

        state.scaleRepetitionsRemaining = playRepetitions
        state.correctAnswersAtCurrentFret = 0
        state.lastPickedNote = nil
        state.rewardNoteTextByString = nil
        state.autoPlayNextDate = nil
        state.pendingRoundShiftBeatPosition = nil
        state.clearReward()
    }

    // MARK: - Reset to Phase 1

    func handleReset(midiEngine: SimpleMIDIEngine) {
        state.resetToPhaseOne()
        currentFret = startingFret
        isDescendingPhase = false
        isScreensaverMode = true
        startupSequenceActivated = true
        startupSequenceStartDate = .now
        startupSequenceElapsed = 0
        questionBoxIntroProgress = 0
        isLaunchTransitionAnimating = false
        launchTileScale = 1
        launchTileOpacity = 1
        isRoundPaused = false
        transportStoppedForResume = false
        isRoundArmed = true
        beatPosition = 0
        beatPositionLastTickDate = nil
        pressedButtonIndex = nil
        pressedButtonCorrect = false

        let lowToHigh = true
        currentGenerator.resetForNewFret()
        currentGenerator.generateNoteSequence(for: currentFret, useFlats: useFlats, lowToHigh: lowToHigh)
        midiEngine.stop()
    }

    // MARK: - Beat Light

    private func updateBeatLight(midiEngine: SimpleMIDIEngine, date: Date) {
        let trackPlaying = midiEngine.isPlaying
        guard trackPlaying, !isScreensaverMode else {
            state.beatLightFlashOn = false
            state.beatLightLastProcessedBeat = nil
            state.beatLightIntroMeasureSkipped = false
            return
        }

        let currentBucket = Int(floor(midiEngine.currentBeatPosition()))

        if state.beatLightLastProcessedBeat == nil {
            state.beatLightLastProcessedBeat = currentBucket
            state.beatLightFlashOn = false
            return
        }

        guard state.beatLightLastProcessedBeat != currentBucket else { return }
        state.beatLightLastProcessedBeat = currentBucket

        if !state.beatLightIntroMeasureSkipped {
            if currentBucket >= 4 {
                state.beatLightIntroMeasureSkipped = true
            } else {
                state.beatLightFlashOn = false
                return
            }
        }

        state.beatLightFlashOn = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
            self?.state.beatLightFlashOn = false
        }
    }
}
