import SwiftUI
import Combine
import AVFoundation

// MARK: - BeginnerGameplayView Logic: Timer-Driven & Session Handlers (Step 4d)

extension BeginnerGameplayView {

    func handleMainTimerTick(_ date: Date) {
        let shouldBlinkStartupStartButton = startupStartButtonAttentionActive && !startupSequenceActivated

        if shouldBlinkStartupStartButton {
            if startupStartButtonNextBlinkDate == nil {
                startupStartButtonBlinkOn = true
                startupStartButtonNextBlinkDate = date.addingTimeInterval(0.45)
            } else if let nextBlinkDate = startupStartButtonNextBlinkDate, date >= nextBlinkDate {
                startupStartButtonBlinkOn.toggle()
                startupStartButtonNextBlinkDate = date.addingTimeInterval(0.45)
            }
        } else {
            startupStartButtonBlinkOn = false
            startupStartButtonNextBlinkDate = nil
        }

        if startupSequenceActivated {
            startupSequenceElapsed = max(date.timeIntervalSince(startupSequenceStartDate), 0)
            let startupState = StartupSequenceView.state(for: startupSequenceElapsed, showFullSequence: layoutMode != .beginner, armedText: beginnerStartupArmedText)
            handleStartupSpeech(for: startupState.phase)
        }

        handlePendingMidiStopIfNeeded()

        if beginnerRuntime.isRoundArmed || isRoundPaused {
            beginnerRuntime.beatLightFlashOn = false
            beginnerRuntime.roundRevealLastTickDate = nil
            return
        }

        if beginnerRuntime.roundRevealLastTickDate == nil {
            beginnerRuntime.roundRevealLastTickDate = date
        } else if let lastTick = beginnerRuntime.roundRevealLastTickDate {
            let delta = max(date.timeIntervalSince(lastTick), 0)
            let beatsPerSecond = Double(max(beatBPM, 60)) / 60.0
            beginnerRuntime.roundRevealElapsedBeats += delta * beatsPerSecond
            beginnerRuntime.roundRevealLastTickDate = date
        }

        handlePendingBeginnerRewardPlaybackIfNeeded()
        handlePendingSequentialRepeatResetIfNeeded()
        handlePendingRoundShiftIfNeeded()
        ensureBeginnerRoundOneRevealSequenceStarted(currentDate: date)
        updateBeginnerRoundOneRevealSequence(currentDate: date)
        updateNoteRevealProgressionIfNeeded()
        handleBeginnerAutoPlayIfNeeded(currentDate: date)

        let trackPlayingNow = midiEngine.isPlaying
        if isBackingTrackPlaying != trackPlayingNow {
            isBackingTrackPlaying = trackPlayingNow
        }

        let shouldRunBeatLight = layoutMode == .beginner && !isCodeScreensaverMode && trackPlayingNow
        if shouldRunBeatLight {
            let currentBeatBucket = Int(floor(midiEngine.currentBeatPosition()))

            if beginnerRuntime.beatLightLastProcessedBeat == nil {
                beginnerRuntime.beatLightLastProcessedBeat = currentBeatBucket
                beginnerRuntime.beatLightFlashOn = false
                return
            }

            if beginnerRuntime.beatLightLastProcessedBeat != currentBeatBucket {
                beginnerRuntime.beatLightLastProcessedBeat = currentBeatBucket

                if !beginnerRuntime.beatLightIntroMeasureSkipped {
                    if currentBeatBucket >= 4 {
                        beginnerRuntime.beatLightIntroMeasureSkipped = true
                    } else {
                        beginnerRuntime.beatLightFlashOn = false
                        return
                    }
                }

                beginnerRuntime.beatLightFlashOn = true
                DispatchQueue.main.asyncAfter(deadline: .now() + AnimationDurations.beatFlash) {
                    beginnerRuntime.beatLightFlashOn = false
                }
            }
        } else {
            beginnerRuntime.beatLightFlashOn = false
            beginnerRuntime.beatLightLastProcessedBeat = nil
            beginnerRuntime.beatLightIntroMeasureSkipped = false
        }
    }

    func applyLivePlayRepetitionChangeIfNeeded() {
        guard layoutMode == .beginner,
              !beginnerRuntime.isRoundArmed,
              !isRoundPaused
        else { return }

        beginnerRuntime.scaleRepetitionsRemaining = beginnerTargetScaleRepetitionsRemaining()
    }

    func beginnerTargetScaleRepetitionsRemaining() -> Int {
        if beginnerRuntime.isDescendingPhase {
            return max(effectivePlayRepetitions - beginnerRuntime.correctAnswersAtCurrentFret, 1)
        }
        return effectivePlayRepetitions
    }

    func updateDirectionLockState() {
        directionLockActive = shouldLockPlayDirection
    }

    func handleContentOnAppear() {
        initializeGameplaySession()
        updateDirectionLockState()
    }

    func initializeGameplaySession() {
        audioSettings = AudioSettings()
        availableBackingTracks = BackingTrack.discoverBundledTracks()
        audioSettings.selectInitialBackingTrackIfNeeded(from: availableBackingTracks)
        guitarNoteEngine.configure(
            preset: audioSettings.guitarTonePreset,
            reverbLevel: audioSettings.reverbLevel,
            delayLevel: audioSettings.delayLevel
        )
        syncBackingTrackPlayback()
        if assetToNutBottomDelta == nil {
            assetToNutBottomDelta = 0
        }
        introDidRun = true
        startupSequenceStartDate = .now
        startupSequenceElapsed = 0
        startupSequenceActivated = false
        introWindowBlack = false
        beginnerRuntime.currentFretStart = 0
        beginnerRuntime.bankDollars = max(walletDollars, 0)
        beginnerRuntime.displayedBankDollars = beginnerRuntime.bankDollars
        showDeveloperPrompt("MODE: \(selectedMode.rawValue.uppercased())")
        beginnerRuntime.questionBoxIntroProgress = isCodeScreensaverMode ? 0 : 1
        beginnerRuntime.answerBoxReady = layoutMode == .beginner ? false : !isCodeScreensaverMode
        beginnerRuntime.isRoundArmed = layoutMode == .beginner
        isRoundPaused = false
        beginnerRuntime.roundRevealElapsedBeats = 0
        beginnerRuntime.roundRevealLastTickDate = nil
    }

    func startGameFromBeginning(animateNeckSlideFromStartup: Bool = false) {
        if layoutMode == .beginner {
            beginnerRuntime.currentRound = beginnerRoundOneStartingFret
            beginnerRuntime.isDescendingPhase = beginnerRoundOneStartsDescending
        } else {
            beginnerRuntime.currentRound = isPhaseDescending ? 12 : 0
            beginnerRuntime.isDescendingPhase = isPhaseDescending
        }
        applyTempoForRound(beginnerRuntime.currentRound)
        if animateNeckSlideFromStartup {
            startupNeckVisualsHidden = true
            beginnerRuntime.currentFretStart = beginnerRuntime.isDescendingPhase ? maxFretOffset : minFretOffset
            DispatchQueue.main.async {
                startupNeckVisualsHidden = false
                withAnimation(.easeInOut(duration: 0.78)) {
                    beginnerRuntime.currentFretStart = beginnerRuntime.currentRound
                }
            }
        } else {
            startupNeckVisualsHidden = false
            beginnerRuntime.currentFretStart = beginnerRuntime.currentRound
        }
        roundStringIndex = 0
        beginnerRuntime.bankDollars = 0
        beginnerRuntime.displayedBankDollars = 0
        walletDollars = 0
        beatQuestionDeadline = nil
        beginnerRuntime.currentPromptStrings = [1]
        beginnerRuntime.activePickedStringNumbers = [1]
        beginnerRuntime.answeredNotesByStringAtCurrentFret = [:]
        beginnerRuntime.beatCountInRemaining = modeVariant == .beat ? 4 : 0
        beginnerRuntime.nextBeatTickDate = nil
        leftThumbState = .neutral
        rightThumbState = .neutral
        beginnerRuntime.activeAnswerFeedback = nil
        beginnerRuntime.isResolvingAnswer = false
        isRoundPaused = false
        beginnerRuntime.roundRevealElapsedBeats = 0
        beginnerRuntime.roundRevealLastTickDate = nil
        gameplayMenuExpanded = false
        developerPromptText = ""
        beginnerRuntime.currentCorrectNote = ""
        beginnerRuntime.lastResolvedCorrectNote = nil
        beginnerRuntime.streakMeterLitColumns = 0
        beginnerRuntime.streakMeterFailureActive = false
        beginnerRuntime.streakMeterFailureVisibleColumns = 0
        beginnerRuntime.correctAnswersAtCurrentFret = 0
        beginnerRuntime.lastPromptedCorrectNote = nil
        beginnerRuntime.lastPromptedStringHalf = nil
        beginnerRuntime.lastPromptedStringNumber = nil
        beginnerRuntime.recentPromptedCorrectNotes = []
        beginnerRuntime.lastPickedNote = nil
        beginnerRuntime.rewardNoteTextByString = nil
        beginnerRuntime.answerBoxReady = layoutMode != .beginner
        beginnerRuntime.autoPlayNextDate = nil
        beginnerRuntime.beatLightFlashOn = false
        beginnerRuntime.beatLightLastProcessedBeat = nil
        beginnerRuntime.roundOneIntroActive = false
        beginnerRuntime.roundOneSequenceStartDate = nil
        beginnerRuntime.beatLightIntroMeasureSkipped = false
        beginnerRuntime.scaleRepetitionsRemaining = effectivePlayRepetitions
        beginnerRuntime.pendingRoundShiftBeatPosition = nil
        beginnerRuntime.scaleSequenceIndex = 0
        beginnerRuntime.scaleStageIndex = 0
        beginnerRuntime.scaleCycleSemitoneOffset = beginnerRuntime.currentRound
        beginnerRuntime.pentatonicRevealCount = 0
        beginnerRuntime.revealStartBeatBucket = nil
        beginnerRuntime.introStartBeatBucket = nil
        beginnerRuntime.showRoundZeroIntroSequence = false
        beginnerRuntime.pendingRewardStageAdvance = false
        beginnerRuntime.rewardTargetBeatPosition = nil
        beginnerRuntime.rewardSelectedString = nil
        beginnerRuntime.rewardNoteTextByString = nil
        beginnerRuntime.rewardScheduledStrings = []
        beginnerRuntime.rewardScheduledMIDINotes = []
        beginnerRuntime.rewardScheduledNoteTextByString = [:]
        beginnerRuntime.rewardSustainMultiplier = 3.0

        // Initialize Sequential style state if needed
        if lessonStyle == .sequential {
            sequentialNoteGenerator.generateNoteSequence(for: beginnerRuntime.currentRound, useFlats: beginnerUsesFlats, lowToHigh: isProgressionLowToHigh)
            beginnerRuntime.sequentialRevealCount = 0
            beginnerRuntime.sequentialRevealStartBeatBucket = nil
            beginnerRuntime.roundOneIntroActive = true
            beginnerRuntime.roundOneSequenceStartDate = Date()
        }

        applyBeginnerBassTransposeForCurrentStage()
        prepareCurrentQuestion()
    }

}
