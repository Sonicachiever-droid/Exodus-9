import SwiftUI
import Combine
import AVFoundation

// MARK: - BeginnerGameplayView Logic: Reward / Progression Handlers (Step 4c)

extension BeginnerGameplayView {

    func beginnerRewardPolicyForCurrentStage() -> BeginnerRewardPolicy? {
        guard layoutMode == .beginner else { return nil }

        let currentFret = max(beginnerRuntime.currentRound, 0)
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

    func beginnerRewardStringAssignments(forChordNotes chordNotes: [String], preferredStrings: [Int]?) -> [(Int, String)] {
        let allStringsDescending = [6, 5, 4, 3, 2, 1]
        let preferredSequence = preferredStrings ?? []
        let fallbackSequence = allStringsDescending.filter { !preferredSequence.contains($0) }
        let candidateSequence = preferredSequence + fallbackSequence
        let rewardDisplayFret = max(beginnerRuntime.currentRound, 0)
        var unusedStrings = candidateSequence
        var assignments: [(Int, String)] = []
        let strictStringPriority = [1, 6, 5, 4, 3, 2]

        for chordNote in chordNotes {
            let matchingStrings = unusedStrings.filter {
                guitarNoteName(forString: $0, fret: rewardDisplayFret, useFlats: false) == chordNote
                    || guitarNoteName(forString: $0, fret: rewardDisplayFret, useFlats: beginnerUsesFlats) == chordNote
            }

            guard let matchedString = strictStringPriority.first(where: { matchingStrings.contains($0) }) else {
                continue
            }
            assignments.append((matchedString, chordNote))
            unusedStrings.removeAll { $0 == matchedString }
        }

        return assignments
    }

    func beginnerRewardChordPayloadForCurrentStage(
        policy: BeginnerRewardPolicy
    ) -> (strings: [Int], notesByString: [Int: String], midiNotes: [Int]) {
        let chordNotes = Array(beginnerCurrentScaleNotes.prefix(5))
        let rewardPairs = beginnerRewardStringAssignments(forChordNotes: chordNotes, preferredStrings: policy.preferredStrings)

        var strings: [Int] = []
        var notesByString: [Int: String] = [:]
        var midiNotes: [Int] = []

        let rewardDisplayFret = max(beginnerRuntime.currentRound, 0)

        for (stringNumber, _) in rewardPairs {
            let displayedNote = guitarNoteName(forString: stringNumber, fret: rewardDisplayFret, useFlats: beginnerUsesFlats)
            guard let midiNote = beginnerRewardMIDINote(for: displayedNote, stringNumber: stringNumber) else { continue }
            strings.append(stringNumber)
            notesByString[stringNumber] = displayedNote
            midiNotes.append(midiNote)
        }

        return (strings, notesByString, midiNotes)
    }

    func beginnerRewardMIDINote(for noteName: String, stringNumber: Int) -> Int? {
        let openMIDINoteByString: [Int: Int] = [6: 40, 5: 45, 4: 50, 3: 55, 2: 59, 1: 64]
        guard let openMIDINote = openMIDINoteByString[stringNumber] else { return nil }

        let targetPitchClass = chromaticSharps.firstIndex(of: noteName)
            ?? chromaticFlats.firstIndex(of: noteName)
        guard let targetPitchClass else { return nil }

        let openPitchClass = openMIDINote % 12
        let fretOffset = (targetPitchClass - openPitchClass + 12) % 12
        return openMIDINote + fretOffset
    }

    func scheduleBeginnerRewardChordThenAdvance(selectedString: Int, policy: BeginnerRewardPolicy) {
        let rewardPayload = beginnerRewardChordPayloadForCurrentStage(policy: policy)
        guard !rewardPayload.midiNotes.isEmpty else {
            advanceBeginnerScaleStage(afterCompletionFromString: selectedString, playTransitionNote: false)
            return
        }

        beginnerRuntime.pendingRewardStageAdvance = true
        beginnerRuntime.rewardSelectedString = selectedString
        beginnerRuntime.rewardTargetBeatPosition = beginnerRuntime.roundRevealElapsedBeats + policy.delayBeats
        beginnerRuntime.rewardScheduledStrings = rewardPayload.strings
        beginnerRuntime.rewardScheduledMIDINotes = rewardPayload.midiNotes
        beginnerRuntime.rewardScheduledNoteTextByString = rewardPayload.notesByString
        beginnerRuntime.rewardSustainMultiplier = policy.sustainMultiplier
        beginnerRuntime.rewardNoteTextByString = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            guard beginnerRuntime.pendingRewardStageAdvance,
                  beginnerRuntime.rewardSelectedString == selectedString,
                  beginnerRuntime.rewardTargetBeatPosition != nil else { return }
            beginnerRuntime.activePickedStringNumbers = []
            beginnerRuntime.lastPickedNote = nil
            beginnerRuntime.answerBoxReady = false
        }
    }

    func scheduleBeginnerAdvanceAfterFinalNoteHold(selectedString: Int, holdSeconds: Double = 0.65) {
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

    func handlePendingBeginnerRewardPlaybackIfNeeded() {
        guard layoutMode == .beginner,
              beginnerRuntime.pendingRewardStageAdvance,
              let targetBeatPosition = beginnerRuntime.rewardTargetBeatPosition,
              let selectedString = beginnerRuntime.rewardSelectedString else { return }

        let currentBeatPosition = beginnerRuntime.roundRevealElapsedBeats
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

        beginnerRuntime.activePickedStringNumbers = beginnerRuntime.rewardScheduledStrings
        beginnerRuntime.answerBoxReady = true
        beginnerRuntime.lastPickedNote = nil
        beginnerRuntime.rewardNoteTextByString = beginnerRuntime.rewardScheduledNoteTextByString
        let rewardChordRingDuration = guitarNoteEngine.playChord(
            midiNotes: beginnerRuntime.rewardScheduledMIDINotes,
            velocity: AudioVelocity.full,
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

    func handlePendingSequentialRepeatResetIfNeeded() {
        guard lessonStyle == .sequential,
              let targetBeatPosition = beginnerRuntime.pendingSequentialRepeatResetBeatPosition else { return }

        guard beginnerRuntime.roundRevealElapsedBeats >= targetBeatPosition else { return }

        beginnerRuntime.pendingSequentialRepeatResetBeatPosition = nil
        sequentialNoteGenerator.resetForNewFret()
        beginnerRuntime.sequentialRevealCount = 0
        beginnerRuntime.sequentialRevealStartBeatBucket = nil
        beginnerRuntime.answerBoxReady = false
        // Clear all answer-display state so the new repetition starts blank.
        // Without this, beginnerRuntime.activePickedStringNumbers and lastPickedNote leak from
        // the just-completed repetition, causing every string to show the
        // previous final answer when beginnerRuntime.answeredNotesByStringAtCurrentFret is empty.
        beginnerRuntime.answeredNotesByStringAtCurrentFret = [:]
        beginnerRuntime.activePickedStringNumbers = []
        beginnerRuntime.lastPickedNote = nil
        beginnerRuntime.rewardNoteTextByString = nil

        let useFlats = layoutMode == .beginner ? beginnerUsesFlats : false
        sequentialNoteGenerator.generateNoteSequence(
            for: max(beginnerRuntime.currentRound, 0),
            useFlats: useFlats,
            lowToHigh: isProgressionLowToHigh
        )
        prepareCurrentQuestion()

        DispatchQueue.main.async {
            beginnerRuntime.pendingSequentialRepeatDisplayText = nil
        }
    }

    func handlePendingRoundShiftIfNeeded() {
        guard lessonStyle == .sequential,
              let targetBeatPosition = beginnerRuntime.pendingRoundShiftBeatPosition else { return }

        let currentBeatPosition = beginnerRuntime.roundRevealElapsedBeats
        guard currentBeatPosition >= targetBeatPosition else { return }

        // 2-beat delay has passed - clear the pending shift and execute
        beginnerRuntime.pendingRoundShiftBeatPosition = nil

        // Clear white note box immediately before shift
        beginnerRuntime.lastPickedNote = nil
        beginnerRuntime.rewardNoteTextByString = nil
        beginnerRuntime.answerBoxReady = false

        // Reset mode state for new fret
        beginnerRuntime.scaleRepetitionsRemaining = effectivePlayRepetitions
        sequentialNoteGenerator.resetForNewFret()
        beginnerRuntime.sequentialRevealCount = 0
        beginnerRuntime.sequentialRevealStartBeatBucket = nil

        // Advance to next fret (or reverse direction at boundary)
        if !beginnerRuntime.isDescendingPhase {
            if beginnerRuntime.currentRound < beginnerUpperFretBoundary {
                beginnerRuntime.currentRound += 1
                beginnerRuntime.answeredNotesByStringAtCurrentFret = [:]
            } else {
                // At boundary - reverse direction
                beginnerRuntime.isDescendingPhase = true
                playDirectionRawValue = LessonDirection.descending.rawValue
                beginnerRuntime.currentRound = beginnerUpperFretBoundary - 1
                beginnerRuntime.answeredNotesByStringAtCurrentFret = [:]
            }
        } else {
            if beginnerRuntime.currentRound > beginnerLowerFretBoundary {
                beginnerRuntime.currentRound -= 1
                beginnerRuntime.answeredNotesByStringAtCurrentFret = [:]
            } else {
                beginnerRuntime.isDescendingPhase = false
                playDirectionRawValue = LessonDirection.ascending.rawValue
                beginnerRuntime.currentRound = 1
                beginnerRuntime.answeredNotesByStringAtCurrentFret = [:]
            }
        }

        applyTempoForRound(beginnerRuntime.currentRound)

        // Generate new sequence for new fret and apply bass transpose
        let useFlats = layoutMode == .beginner ? beginnerUsesFlats : false
        sequentialNoteGenerator.generateNoteSequence(for: max(beginnerRuntime.currentRound, 0), useFlats: useFlats, lowToHigh: isProgressionLowToHigh)
        applyBeginnerBassTransposeForCurrentStage()
        prepareCurrentQuestion()
    }

    func handlePendingMidiStopIfNeeded() {
        guard layoutMode == .beginner,
              let stopDate = beginnerRuntime.pendingMidiStopDate else { return }
        guard Date() >= stopDate else { return }

        // 3-beat delay has passed - stop the MIDI playback
        beginnerRuntime.pendingMidiStopDate = nil
        midiEngine.stop()
        isBackingTrackPlaying = false
    }

    func advanceBeginnerScaleStage(afterCompletionFromString selectedString: Int, playTransitionNote: Bool = true) {
        beginnerRuntime.autoPlayLastStringByNote = [:]
        let completedStageWasCycleEnd = beginnerCurrentScaleStage.endsCycle
        beginnerRuntime.rewardNoteTextByString = nil
        beginnerRuntime.rewardScheduledStrings = []
        beginnerRuntime.rewardScheduledMIDINotes = []
        beginnerRuntime.rewardScheduledNoteTextByString = [:]
        beginnerRuntime.rewardSustainMultiplier = 3.0
        beginnerRuntime.scaleRepetitionsRemaining = effectivePlayRepetitions
        if completedStageWasCycleEnd {
            beginnerRuntime.scaleRepetitionsRemaining -= 1
            if beginnerRuntime.scaleRepetitionsRemaining > 0 {
                beginnerRuntime.scaleStageIndex = 0
                beginnerRuntime.scaleSequenceIndex = 0
                beginnerRuntime.pentatonicRevealCount = 0
                beginnerRuntime.roundOneIntroActive = true
                beginnerRuntime.roundOneSequenceStartDate = Date()
                beginnerRuntime.roundRevealElapsedBeats = 0
                if lessonStyle == .chord {
                    beginnerRuntime.showRoundZeroIntroSequence = true
                    beginnerRuntime.introStartBeatBucket = 0
                }
                return
            }
        }
        if completedStageWasCycleEnd {
            let nextFret: Int?
            if beginnerRuntime.isDescendingPhase {
                nextFret = beginnerRuntime.currentRound > beginnerLowerFretBoundary ? beginnerRuntime.currentRound - 1 : nil
            } else {
                nextFret = beginnerRuntime.currentRound < beginnerUpperFretBoundary ? beginnerRuntime.currentRound + 1 : nil
            }

            if let nextFret {
                beginnerRuntime.currentRound = nextFret
                beginnerRuntime.scaleCycleSemitoneOffset = nextFret
                beginnerRuntime.scaleStageIndex = 0
                beginnerRuntime.scaleSequenceIndex = 0
                beginnerRuntime.pentatonicRevealCount = 0
                beginnerRuntime.roundOneIntroActive = false
                beginnerRuntime.roundOneSequenceStartDate = nil
                beginnerRuntime.revealStartBeatBucket = nil
                beginnerRuntime.introStartBeatBucket = nil
                beginnerRuntime.rewardSelectedString = nil
            } else {
                // At boundary - reverse direction and keep the shared binding aligned
                if beginnerRuntime.isDescendingPhase {
                    beginnerRuntime.isDescendingPhase = false
                    playDirectionRawValue = LessonDirection.ascending.rawValue
                    beginnerRuntime.currentRound = 1
                } else {
                    beginnerRuntime.isDescendingPhase = true
                    playDirectionRawValue = LessonDirection.descending.rawValue
                    beginnerRuntime.currentRound = beginnerUpperFretBoundary - 1
                }
            }
        } else {
            beginnerRuntime.scaleStageIndex = min(beginnerRuntime.scaleStageIndex + 1, beginnerScaleStages.count - 1)
        }
        beginnerRuntime.scaleSequenceIndex = 0
        beginnerRuntime.pentatonicRevealCount = 0
        beginnerRuntime.roundOneIntroActive = true
        beginnerRuntime.roundOneSequenceStartDate = Date()
        beginnerRuntime.roundRevealElapsedBeats = 0
        if lessonStyle == .chord {
            beginnerRuntime.showRoundZeroIntroSequence = true
            beginnerRuntime.introStartBeatBucket = 0
        }
        beginnerRuntime.roundRevealLastTickDate = nil
        beginnerRuntime.answerBoxReady = false
        beginnerRuntime.lastPickedNote = nil
        applyTempoForRound(beginnerRuntime.currentRound)
        applyBeginnerBassTransposeForCurrentStage()
        if playTransitionNote {
            playGuitarNote(forString: selectedString, fret: max(beginnerRuntime.currentRound, 0), velocity: AudioVelocity.full)
        }
    }

    func transposedSharpNote(_ note: String, by semitones: Int) -> String {
        transposedNote(note, by: semitones, useFlats: false)
    }

    func transposedNote(_ note: String, by semitones: Int, useFlats: Bool) -> String {
        guard let index = chromaticSharps.firstIndex(of: note) else { return note }
        let wrapped = (index + semitones % chromaticSharps.count + chromaticSharps.count) % chromaticSharps.count
        let scale = useFlats ? chromaticFlats : chromaticSharps
        return scale[wrapped]
    }

    func applyBeginnerBassTransposeForCurrentStage() {
        guard layoutMode == .beginner else {
            midiEngine.setBassTransposeSemitones(0)
            return
        }

        if !beginnerRuntime.isDescendingPhase {
            if lessonStyle == .sequential {
                let transposeSemitones = playEnableHighFrets ? max(beginnerRuntime.currentRound, 0) % 12 : max(beginnerRuntime.currentRound, 0)
                midiEngine.setBassTransposeSemitones(transposeSemitones)
            } else {
                midiEngine.setBassTransposeSemitones(beginnerCurrentBassSemitoneTarget)
            }
            return
        }

        if beginnerRuntime.isDescendingPhase {
            midiEngine.setBassTransposeSemitones(max(beginnerRuntime.currentRound, 0) % 12)
            return
        }

        midiEngine.setBassTransposeSemitones(0)
    }

    func ensureBeginnerRoundOneRevealSequenceStarted(currentDate: Date) {
        guard layoutMode == .beginner,
              !isCodeScreensaverMode,
              !startupSequenceActivated,
              lessonStyle == .chord,
              beginnerRuntime.questionBoxIntroProgress > 0,
              beginnerRuntime.roundOneSequenceStartDate == nil,
              beginnerRuntime.pentatonicRevealCount == 0,
              !beginnerRuntime.answerBoxReady,
              !beginnerRuntime.isRoundArmed
        else { return }

        beginnerRuntime.roundOneIntroActive = true
        beginnerRuntime.roundOneSequenceStartDate = currentDate
        beginnerRuntime.pentatonicRevealCount = 0
        beginnerRuntime.revealStartBeatBucket = nil
        beginnerRuntime.introStartBeatBucket = Int(floor(beginnerRuntime.roundRevealElapsedBeats))
        beginnerRuntime.showRoundZeroIntroSequence = lessonStyle == .chord ? true : shouldShowLegacyRoundZeroIntro
        beginnerRuntime.lastPickedNote = nil
        beginnerRuntime.answerBoxReady = false
    }

    func updateBeginnerRoundOneRevealSequence(currentDate _: Date) {
        guard beginnerRuntime.roundOneIntroActive,
              beginnerRuntime.roundOneSequenceStartDate != nil,
              layoutMode == .beginner,
              lessonStyle == .chord,
              !isCodeScreensaverMode,
              !startupSequenceActivated
        else { return }

        guard beginnerRoundZeroIntroDisplayPhase == .noteReveal else { return }
        let currentBeatBucket = Int(floor(beginnerRuntime.roundRevealElapsedBeats))
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

    func updateNoteRevealProgressionIfNeeded() {
        guard layoutMode == .beginner,
              lessonStyle == .sequential,
              !isCodeScreensaverMode,
              !startupSequenceActivated
        else { return }

        let currentBeatBucket = Int(floor(beginnerRuntime.roundRevealElapsedBeats))
        if beginnerRuntime.revealStartBeatBucket == nil {
            beginnerRuntime.revealStartBeatBucket = currentBeatBucket
        }
        let startBucket = beginnerRuntime.revealStartBeatBucket ?? currentBeatBucket
        let elapsedBeatBuckets = max(currentBeatBucket - startBucket, 0)
        let clampedRevealCount = min(elapsedBeatBuckets + 1, GameConstants.maxRevealCount)

        if clampedRevealCount != beginnerRuntime.revealCount {
            beginnerRuntime.revealCount = clampedRevealCount
        }
        if clampedRevealCount >= GameConstants.maxRevealCount {
            beginnerRuntime.answerBoxReady = true
        }
        if elapsedBeatBuckets >= GameConstants.maxRevealCount {
            beginnerRuntime.roundOneIntroActive = false
            beginnerRuntime.roundOneSequenceStartDate = nil
        }
    }

    func handleBeginnerAutoPlayIfNeeded(currentDate: Date) {
        guard layoutMode == .beginner,
              beginnerRuntime.autoPlayEnabled,
              !isCodeScreensaverMode,
              !startupSequenceActivated,
              !beginnerRuntime.isResolvingAnswer,
              !beginnerRuntime.pendingRewardStageAdvance,
              beginnerRuntime.pendingRoundShiftBeatPosition == nil
        else {
            if layoutMode != .beginner || !beginnerRuntime.autoPlayEnabled {
                beginnerRuntime.autoPlayNextDate = nil
            }
            return
        }

        let fret = max(beginnerRuntime.currentRound, 0)

        if lessonStyle == .sequential {
            guard beginnerRuntime.revealCount >= GameConstants.maxRevealCount else {
                beginnerRuntime.autoPlayNextDate = nil
                return
            }
            let revealElapsed = Int(floor(beginnerRuntime.roundRevealElapsedBeats)) - (beginnerRuntime.revealStartBeatBucket ?? Int(floor(beginnerRuntime.roundRevealElapsedBeats)))
            guard revealElapsed >= GameConstants.maxRevealCount + 1 else {
                beginnerRuntime.autoPlayNextDate = nil
                return
            }
            guard !currentGenerator.isSequenceComplete() else {
                beginnerRuntime.autoPlayNextDate = nil
                return
            }
            let idx = currentGenerator.sequenceProgressIndex
            guard let nextString = currentGenerator.expectedString,
                  currentGenerator.currentNoteSequence.indices.contains(idx)
            else {
                beginnerRuntime.autoPlayNextDate = nil
                return
            }
            let nextNote = currentGenerator.currentNoteSequence[idx]
            let bps = Double(max(audioSettings.startingBPM, 40)) / 60.0
            let oneBeat = 1.0 / bps
            if beginnerRuntime.autoPlayNextDate == nil {
                beginnerRuntime.autoPlayNextDate = nextOnAndThreeBeatDate(after: currentDate)
                return
            }
            guard let nextDate = beginnerRuntime.autoPlayNextDate, currentDate >= nextDate else { return }
            // If we're more than one beat late, the date is stale — reschedule cleanly
            if currentDate.timeIntervalSince(nextDate) > oneBeat {
                beginnerRuntime.autoPlayNextDate = nextOnAndThreeBeatDate(after: currentDate)
                return
            }
            let buttonIndex = nextString >= 4 ? (nextString - 4) : (6 - nextString)
            beginnerRuntime.isAutoPlayTriggered = true
            handleBeginnerConsoleButtonPress(selectedNote: nextNote, selectedString: nextString, buttonIndex: buttonIndex)
            beginnerRuntime.isAutoPlayTriggered = false
            beginnerRuntime.autoPlayNextDate = nextOnAndThreeBeatDate(after: currentDate)
            return
        } else {
            // Chord style: existing behavior
            guard lessonStyle == .chord,
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

            // NOTE: Chord style uses the original fixed interval rather than beat-locking.
            // Beat-locked timing (nextOnAndThreeBeatDate) works well for sequential and
            // Maestro but conflicts with chord's multi-note scale stage logic. May revisit.
            if beginnerRuntime.autoPlayNextDate == nil {
                beginnerRuntime.autoPlayNextDate = currentDate.addingTimeInterval(GameConstants.autoPlayInterval)
                return
            }
            guard let nextDate = beginnerRuntime.autoPlayNextDate, currentDate >= nextDate else { return }
            let preferredStringOrder = beginnerAutoPlayPreferredStringOrder(for: expectedNote)
            let matchedString = preferredStringOrder.first {
                guitarNoteName(forString: $0, fret: fret, useFlats: false) == expectedNote
            } ?? preferredStringOrder.first {
                guitarNoteName(forString: $0, fret: fret, useFlats: beginnerUsesFlats) == expectedNote
            }
            guard let selectedString = matchedString else {
                beginnerRuntime.autoPlayNextDate = currentDate.addingTimeInterval(GameConstants.autoPlayInterval)
                return
            }
            beginnerRuntime.autoPlayLastStringByNote[expectedNote] = selectedString
            let buttonIndex = selectedString <= 3 ? (6 - selectedString) : (selectedString - 4)
            beginnerRuntime.isAutoPlayTriggered = true
            handleBeginnerConsoleButtonPress(selectedNote: expectedNote, selectedString: selectedString, buttonIndex: buttonIndex)
            beginnerRuntime.isAutoPlayTriggered = false
            beginnerRuntime.autoPlayNextDate = currentDate.addingTimeInterval(GameConstants.autoPlayInterval)
        }
    }

    func beginnerAutoPlayPreferredStringOrder(for expectedNote: String) -> [Int] {
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

        // Force alternation between string 1 and 6 for notes that appear on both
        if let lastString = beginnerRuntime.autoPlayLastStringByNote[expectedNote] {
            if lastString == 6 { return highToLow }
            if lastString == 1 { return lowToHigh }
        }

        return lowToHigh
    }
}
