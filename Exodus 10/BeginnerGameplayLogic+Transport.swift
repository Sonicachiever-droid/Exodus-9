import SwiftUI
import Combine
import AVFoundation

// MARK: - BeginnerGameplayView Logic: Transport Handlers (Step 4a)
// Extracted from BeginnerGameplayView.swift.
// These are methods on BeginnerGameplayView so they have full access to all
// view state and can call sibling functions without any architectural changes.

extension BeginnerGameplayView {

    // MARK: - Menu / Audio / Fretboard

    func handleGameplayMenuSelection(_ option: GameplayMenuOption) {
        gameplayMenuExpanded = false
        if !isCodeScreensaverMode && !beginnerRuntime.isRoundArmed && !isRoundPaused {
            handleRoundStopButton()
        }
        if option == .audio {
            availableBackingTracks = BackingTrack.discoverBundledTracks()
            audioSettings.selectInitialBackingTrackIfNeeded(from: availableBackingTracks)
            showAudioPage = true
            showDeveloperPrompt("MENU: AUDIO")
            return
        }
        onMenuSelection?(option)
        showDeveloperPrompt("MENU: \(option.title)")
    }

    func handleAudioPageDismiss() {
        if beginnerRuntime.transportStoppedForResume {
            resumeRoundFromTransportStop()
        }
    }

    func handleFretboardButtonPress() {
        showFretboardGuide.toggle()
        postponeBeatDeadlineForAssist()
        showDeveloperPrompt(showFretboardGuide ? "Fretboard guide ON" : "Fretboard guide OFF")
    }

    func handleHintButtonPress() {
        postponeBeatDeadlineForAssist()
        if layoutMode == .beginner {
            showFretboardGuide.toggle()
        }
        showDeveloperPrompt("HINT: \(guitarNoteDisplayText(beginnerRuntime.currentCorrectNote))")
    }

    // MARK: - Round Start

    func handleRoundStartButton(animateNeckSlideFromStartup: Bool = false) {
        if isCodeScreensaverMode {
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
                isLaunchTransitionAnimating = false
                launchTileScale = 1
                launchTileOpacity = 1
                beginnerRuntime.questionBoxIntroProgress = 1
                handleRoundStartButton(animateNeckSlideFromStartup: true)
            }
            return
        }

        if layoutMode == .beginner {
            beginnerRuntime.reset()
        }
        isCodeScreensaverMode = false
        startupSequenceActivated = false
        startupSequenceElapsed = 0
        startupSpeechPhase = .idle
        beginnerRuntime.questionBoxIntroProgress = 1
        isRoundPaused = false
        beginnerRuntime.transportStoppedForResume = false
        beginnerRuntime.isRoundArmed = false
        beginnerRuntime.roundRevealElapsedBeats = 0
        beginnerRuntime.roundRevealLastTickDate = nil

        // Ensure reveal beat-buckets are always fresh for the active style at START
        if lessonStyle == .sequential {
            beginnerRuntime.sequentialRevealCount = 0
            beginnerRuntime.sequentialRevealStartBeatBucket = nil
        }

        startGameFromBeginning(animateNeckSlideFromStartup: animateNeckSlideFromStartup)
        updateDirectionLockState()
        if !animateNeckSlideFromStartup {
            syncBackingTrackPlayback()
        }
    }

    func handleStartButtonPress() {
        if startupStartButtonAttentionActive,
           layoutMode == .beginner,
           isCodeScreensaverMode,
           !startupSequenceActivated {
            startupSequenceActivated = true
            startupSequenceStartDate = .now
            startupSequenceElapsed = 0
            startupSpeechPhase = .pendingArmed
            beginnerRuntime.questionBoxIntroProgress = 0
            return
        }

        if beginnerRuntime.transportStoppedForResume {
            resumeRoundFromTransportStop()
            return
        }

        if isRoundPaused {
            resumeRoundFromTransportStop(forceIfPaused: true)
            return
        }

        if !beginnerRuntime.isRoundArmed {
            handleRoundResetButton()
            return
        }

        handleRoundStartButton()
    }

    // MARK: - Round Stop / Pause / Resume

    func handleRoundStopButton() {
        guard canPressStopButton else { return }

        isRoundPaused = true
        beginnerRuntime.transportStoppedForResume = true
        beginnerRuntime.roundRevealLastTickDate = nil
        midiEngine.pause()
        isBackingTrackPlaying = midiEngine.isPlaying
        beginnerRuntime.beatLightFlashOn = false
        beginnerRuntime.beatLightLastProcessedBeat = nil
        beginnerRuntime.beatLightIntroMeasureSkipped = false
        updateDirectionLockState()
    }

    func resumeRoundFromTransportStop(forceIfPaused: Bool = false) {
        guard beginnerRuntime.transportStoppedForResume || (forceIfPaused && isRoundPaused) else { return }

        beginnerRuntime.transportStoppedForResume = false
        isRoundPaused = false
        beginnerRuntime.roundRevealLastTickDate = nil
        midiEngine.resume()
        beginnerRuntime.beatLightFlashOn = false
        beginnerRuntime.beatLightLastProcessedBeat = nil
        beginnerRuntime.beatLightIntroMeasureSkipped = false
        updateDirectionLockState()
    }

    // MARK: - Reset

    func handleRoundResetButton() {
        beginnerRuntime.resetButtonPressed = true
        DispatchQueue.main.asyncAfter(deadline: .now() + AnimationDurations.resetDelay) {
            beginnerRuntime.resetButtonPressed = false
        }

        if layoutMode == .beginner {
            beginnerRuntime.reset()
        }
        isCodeScreensaverMode = true
        startupSequenceActivated = true
        startupSequenceStartDate = .now
        startupSequenceElapsed = 0
        startupSpeechPhase = .pendingArmed
        beginnerRuntime.questionBoxIntroProgress = 0
        isLaunchTransitionAnimating = false
        launchTileScale = 1
        launchTileOpacity = 1
        isRoundPaused = false
        beginnerRuntime.transportStoppedForResume = false
        beginnerRuntime.isRoundArmed = true
        beginnerRuntime.roundRevealElapsedBeats = 0
        beginnerRuntime.roundRevealLastTickDate = nil
        syncBackingTrackPlayback()
        startGameFromBeginning()
        developerPromptText = ""
        beginnerRuntime.answerBoxReady = false
        updateDirectionLockState()
    }
}
