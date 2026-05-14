import SwiftUI
import Combine
import AVFoundation

// MARK: - BeginnerGameplayView Logic: Answer / Submission Handlers (Step 4b)

extension BeginnerGameplayView {

    // MARK: - Maestro answer submission (thumb buttons)

    func submitAnswer(_ side: AnswerSide, force: Bool = false) {
        if layoutMode == .beginner && beginnerRuntime.isRoundArmed {
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
                beginnerRuntime.questionBoxIntroProgress = 0
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
            withAnimation(.easeIn(duration: AnimationDurations.launchTransition)) {
                launchTileScale = 0.1
                launchTileOpacity = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + AnimationDurations.launchTransition) {
                isCodeScreensaverMode = false
                startupSequenceActivated = false
                startupSequenceElapsed = 0
                startupSpeechPhase = .idle
                startGameFromBeginning(animateNeckSlideFromStartup: true)
                isLaunchTransitionAnimating = false
                launchTileScale = 1
                launchTileOpacity = 1
                withAnimation(.easeOut(duration: 0.6)) {
                    beginnerRuntime.questionBoxIntroProgress = 1
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

        guard force || !beginnerRuntime.isResolvingAnswer else { return }
        beginnerRuntime.isResolvingAnswer = true
        beatQuestionDeadline = nil
        playCurrentPromptedGuitarNotes(velocity: force ? AudioVelocity.soft : 0.94)

        let isCorrect = side == beginnerRuntime.correctAnswerSide
        if isCorrect {
            if side == .left {
                leftThumbState = .green
            } else {
                rightThumbState = .green
            }
            beginnerRuntime.activeAnswerFeedback = .green
            beginnerRuntime.lastResolvedCorrectNote = beginnerRuntime.currentCorrectNote
            beginnerRuntime.lastResolvedCorrectString = beginnerRuntime.currentPromptStrings.first
        } else {
            if side == .left {
                leftThumbState = .red
            } else {
                rightThumbState = .red
            }
            beginnerRuntime.activeAnswerFeedback = .red
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            leftThumbState = .neutral
            rightThumbState = .neutral
            questionBoxAssistActive = false
            if isCorrect {
                beginnerRuntime.isResolvingAnswer = false
                advanceGame(afterCorrectAnswer: true)
            } else {
                advanceGame(afterCorrectAnswer: false)
            }
        }
    }

    // MARK: - Game progression

    func advanceGame(afterCorrectAnswer isCorrect: Bool) {
        if !isCorrect {
            beginnerRuntime.isResolvingAnswer = false
            prepareCurrentQuestion()
            return
        }

        // Skip point earning for autoplay
        guard !beginnerRuntime.isAutoPlayTriggered else {
            prepareCurrentQuestion()
            return
        }

        beginnerRuntime.correctAnswersAtCurrentFret = min(beginnerRuntime.correctAnswersAtCurrentFret + 1, 20)
        let payout = payoutForRound(beginnerRuntime.currentRound)
        beginnerRuntime.bankDollars += payout
        beginnerRuntime.displayedBankDollars = beginnerRuntime.bankDollars
        walletDollars = beginnerRuntime.bankDollars
        balanceDollars += payout

        if layoutMode == .beginner {
            if beginnerRuntime.isDescendingPhase {
                let requiredCorrectAnswers = effectivePlayRepetitions
                let completedAtCurrentFret = beginnerRuntime.correctAnswersAtCurrentFret

                if completedAtCurrentFret >= requiredCorrectAnswers {
                    beginnerRuntime.correctAnswersAtCurrentFret = 0

                    if beginnerRoundTwoStartsDescending {
                        if beginnerRuntime.currentRound > beginnerLowerFretBoundary {
                            beginnerRuntime.currentRound -= 1
                            prepareCurrentQuestion()
                        } else {
                            startGameFromBeginning()
                            return
                        }
                    } else {
                        if beginnerRuntime.currentRound < beginnerUpperFretBoundary {
                            beginnerRuntime.currentRound += 1
                            beginnerRuntime.answeredNotesByStringAtCurrentFret = [:]
                            prepareCurrentQuestion()
                        } else {
                            startGameFromBeginning()
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

        if roundStringIndex < activeStringOrder.count - 1 {
            roundStringIndex += 1
        } else {
            roundStringIndex = 0
            if !beginnerRuntime.isDescendingPhase {
                if beginnerRuntime.currentRound < beginnerUpperFretBoundary {
                    beginnerRuntime.currentRound += 1
                    beginnerRuntime.answeredNotesByStringAtCurrentFret = [:]
                } else {
                    startGameFromBeginning()
                    return
                }
            } else {
                if beginnerRuntime.currentRound > beginnerLowerFretBoundary {
                    beginnerRuntime.currentRound -= 1
                    beginnerRuntime.answeredNotesByStringAtCurrentFret = [:]
                } else {
                    startGameFromBeginning()
                    return
                }
            }
        }
    }

    func prepareCurrentQuestion() {
        if lessonStyle == .sequential {
            // Sequential style: use SequentialNoteGenerator
            let idx = sequentialNoteGenerator.sequenceProgressIndex
            guard idx < sequentialNoteGenerator.currentNoteSequence.count,
                  let nextString = sequentialNoteGenerator.expectedString else { return }
            let correctNote = sequentialNoteGenerator.currentNoteSequence[idx]
            let useFlats = layoutMode == .beginner ? beginnerUsesFlats : false
            let incorrectNote = randomIncorrectNote(excluding: correctNote, useFlats: useFlats)
            let correctOnLeft = Bool.random()
            if correctOnLeft {
                beginnerRuntime.leftChoiceNote = correctNote
                beginnerRuntime.rightChoiceNote = incorrectNote
            } else {
                beginnerRuntime.leftChoiceNote = incorrectNote
                beginnerRuntime.rightChoiceNote = correctNote
            }
            beginnerRuntime.correctAnswerSide = correctOnLeft ? .left : .right
            beginnerRuntime.currentPromptStrings = [nextString]
            beginnerRuntime.lastPromptedCorrectNote = correctNote
            beginnerRuntime.lastPromptedStringHalf = .left
            beginnerRuntime.lastPromptedStringNumber = nextString
            withAnimation(.easeInOut(duration: 1.3)) {
                beginnerRuntime.currentFretStart = max(beginnerRuntime.currentRound, 0)
            }
        } else {
            // Chord style: existing behavior
            let fret = max(beginnerRuntime.currentRound, 0)
            let useFlats = layoutMode == .beginner ? beginnerUsesFlats : false
            let targetString = activeStringOrder.isEmpty ? 1 : activeStringOrder.randomElement() ?? 1
            let correctNote = guitarNoteName(forString: targetString, fret: fret, useFlats: useFlats)
            let incorrectNote = randomIncorrectNote(excluding: correctNote, useFlats: useFlats)
            let correctOnLeft = Bool.random()

            if correctOnLeft {
                beginnerRuntime.leftChoiceNote = correctNote
                beginnerRuntime.rightChoiceNote = incorrectNote
            } else {
                beginnerRuntime.leftChoiceNote = incorrectNote
                beginnerRuntime.rightChoiceNote = correctNote
            }

            beginnerRuntime.currentPromptStrings = [targetString]
            beginnerRuntime.lastPromptedCorrectNote = correctNote
            withAnimation(.easeInOut(duration: 1.3)) {
                beginnerRuntime.currentFretStart = fret
            }
        }
    }

    func payoutForRound(_ round: Int) -> Int {
        _ = round
        return 1
    }

    func randomIncorrectNote(excluding correct: String, useFlats: Bool) -> String {
        let source = useFlats ? chromaticFlats : chromaticSharps
        let pool = source.filter { $0 != correct }
        return pool.randomElement() ?? "C"
    }

    // MARK: - Beginner console button handling

    func handleBeginnerConsoleButtonPress(selectedNote: String, selectedString: Int, buttonIndex: Int) {
        guard layoutMode == .beginner else { return }
        if beginnerRuntime.isRoundArmed {
            handleRoundStartButton()
            return
        }
        if isCodeScreensaverMode {
            submitAnswer(.left)
            return
        }

        let canAdvanceBeginnerProgression = !beginnerRuntime.isResolvingAnswer
            && !beginnerRuntime.pendingRewardStageAdvance
            && !beginnerRuntime.roundOneIntroActive

        if lessonStyle == .sequential {
            beginnerRuntime.activePickedStringNumbers = Array(beginnerRuntime.answeredNotesByStringAtCurrentFret.keys)
        } else {
            beginnerRuntime.activePickedStringNumbers = [selectedString]
        }
        beginnerRuntime.rewardNoteTextByString = nil
        beginnerRuntime.lastPickedNote = lessonStyle == .sequential ? nil : selectedNote
        if lessonStyle != .sequential {
            beginnerRuntime.answeredNotesByStringAtCurrentFret[selectedString] = selectedNote
        }
        beginnerRuntime.answerBoxReady = true
        beginnerRuntime.activeAnswerFeedback = nil
        questionBoxAssistActive = false

        guard canAdvanceBeginnerProgression else {
            playGuitarNote(forString: selectedString, fret: max(beginnerRuntime.currentRound, 0), velocity: AudioVelocity.full)
            return
        }

        if lessonStyle == .sequential {
            handleBeginnerRoundOneProgressionIfNeeded(selectedNote: selectedNote, selectedString: selectedString, buttonIndex: buttonIndex)
        } else if lessonStyle == .chord {
            handleBeginnerChordProgressionIfNeeded(selectedNote: selectedNote, selectedString: selectedString, buttonIndex: buttonIndex)
        }

        playGuitarNote(forString: selectedString, fret: max(beginnerRuntime.currentRound, 0), velocity: AudioVelocity.full)
    }

    func handleBeginnerRoundOneProgressionIfNeeded(selectedNote: String, selectedString: Int, buttonIndex: Int) {
        guard lessonStyle == .sequential else { return }

        guard !sequentialNoteGenerator.currentNoteSequence.isEmpty else { return }
        guard !sequentialNoteGenerator.isSequenceComplete() else { return }

        guard sequentialNoteGenerator.isValidAnswer(note: selectedNote, string: selectedString) else {
            // Wrong answer — restart the sequence
            let useFlats = layoutMode == .beginner ? beginnerUsesFlats : false
            sequentialNoteGenerator.resetForNewFret()
            sequentialNoteGenerator.generateNoteSequence(
                for: max(beginnerRuntime.currentRound, 0),
                useFlats: useFlats,
                lowToHigh: isProgressionLowToHigh
            )
            beginnerRuntime.sequentialRevealCount = 0
            beginnerRuntime.sequentialRevealStartBeatBucket = nil
            beginnerRuntime.answeredNotesByStringAtCurrentFret = [:]
            beginnerRuntime.activePickedStringNumbers = []
            beginnerRuntime.lastPickedNote = nil
            beginnerRuntime.answerBoxReady = false
            return
        }

        // Correct answer — commit to answered set
        beginnerRuntime.answeredNotesByStringAtCurrentFret[selectedString] = selectedNote
        beginnerRuntime.activePickedStringNumbers = Array(beginnerRuntime.answeredNotesByStringAtCurrentFret.keys)
        beginnerRuntime.lastPickedNote = selectedNote

        beginnerPressedButtonIndex = buttonIndex
        beginnerPressedButtonCorrect = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            beginnerPressedButtonIndex = nil
            beginnerPressedButtonCorrect = false
        }
        if !beginnerRuntime.isAutoPlayTriggered {
            let payout = payoutForRound(beginnerRuntime.currentRound)
            beginnerRuntime.bankDollars += payout
            beginnerRuntime.displayedBankDollars = beginnerRuntime.bankDollars
            walletDollars = beginnerRuntime.bankDollars
            balanceDollars += payout
        }
        sequentialNoteGenerator.advanceSequence()

        if sequentialNoteGenerator.isSequenceComplete() {
            if beginnerRuntime.scaleRepetitionsRemaining <= 1 {
                if beginnerRuntime.pendingRoundShiftBeatPosition == nil {
                    beginnerRuntime.pendingRoundShiftBeatPosition = beginnerRuntime.roundRevealElapsedBeats + 2.0
                }
            } else {
                beginnerRuntime.scaleRepetitionsRemaining -= 1
                beginnerRuntime.pendingSequentialRepeatDisplayText = sequentialNoteGenerator.currentNoteSequence
                    .map(guitarNoteDisplayText)
                    .joined(separator: " ")
                beginnerRuntime.pendingSequentialRepeatResetBeatPosition = beginnerRuntime.roundRevealElapsedBeats + 2.0
            }
        }
    }

    func handleBeginnerChordProgressionIfNeeded(selectedNote: String, selectedString: Int, buttonIndex: Int) {
        guard lessonStyle == .chord,
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
            beginnerPressedButtonIndex = buttonIndex
            beginnerPressedButtonCorrect = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                beginnerPressedButtonIndex = nil
                beginnerPressedButtonCorrect = false
            }
            if !beginnerRuntime.isAutoPlayTriggered {
                let payout = payoutForRound(beginnerRuntime.currentRound)
                beginnerRuntime.bankDollars += payout
                beginnerRuntime.displayedBankDollars = beginnerRuntime.bankDollars
                walletDollars = beginnerRuntime.bankDollars
                balanceDollars += payout
            }
            if safeSequenceIndex == currentScaleNotes.count - 1 {
                if let rewardPolicy = beginnerRewardPolicyForCurrentStage() {
                    playGuitarNote(forString: selectedString, fret: max(beginnerRuntime.currentRound, 0), velocity: AudioVelocity.full)
                    scheduleBeginnerRewardChordThenAdvance(selectedString: selectedString, policy: rewardPolicy)
                } else {
                    playGuitarNote(forString: selectedString, fret: max(beginnerRuntime.currentRound, 0), velocity: AudioVelocity.full)
                    scheduleBeginnerAdvanceAfterFinalNoteHold(selectedString: selectedString)
                }
                return
            } else {
                beginnerRuntime.scaleSequenceIndex += 1
            }
        } else {
            beginnerPressedButtonIndex = buttonIndex
            beginnerPressedButtonCorrect = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                beginnerPressedButtonIndex = nil
                beginnerPressedButtonCorrect = false
            }
            beginnerRuntime.scaleSequenceIndex = (selectedNote == currentScaleNotes[0]) ? 1 : 0
        }
    }

    // MARK: - Audio playback helpers

    func playCurrentPromptedGuitarNotes(velocity: Float) {
        let fret = max(beginnerRuntime.currentRound, 0)
        let promptStrings = beginnerRuntime.currentPromptStrings.isEmpty ? [1] : beginnerRuntime.currentPromptStrings
        for (index, stringNumber) in promptStrings.enumerated() {
            let delay = Double(index) * 0.035
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                playGuitarNote(forString: stringNumber, fret: fret, velocity: velocity)
            }
        }
    }

    func playGuitarNote(forString stringNumber: Int, fret: Int, velocity: Float) {
        guitarNoteEngine.play(string: stringNumber, fret: max(fret, 0), velocity: velocity)
    }
}
