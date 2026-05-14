import SwiftUI
import Combine
import AVFoundation

// MARK: - MaestroGameplayView Logic
// Extracted from MaestroGameplayView.swift.
// These are methods on MaestroGameplayView so they have full access to all
// view state and can call sibling functions without any architectural changes.

extension MaestroGameplayView {

    // MARK: - Tempo

    func applyTempoForRound(_ round: Int) {
        let increase = audioSettings.tempoIncreasePerRound.rawValue
        let effective = max(audioSettings.startingBPM + round * increase, 40)
        SharedAudioEngine.shared.setTempo(bpm: Double(effective))
    }

    func nextOnAndThreeBeatDate(after date: Date, waitForDownbeat: Bool = false) -> Date {
        let bpm = Double(max(audioSettings.startingBPM, 40))
        let secondsPerBeat = 60.0 / bpm
        guard midiEngine.isPlaying else {
            return date.addingTimeInterval(secondsPerBeat * 2)
        }
        let currentBeat = midiEngine.currentBeatPosition()
        let currentBeatFloor = floor(currentBeat)
        let beatInMeasure = Int(currentBeatFloor) % 4
        let fractionalRemaining = (currentBeatFloor + 1.0) - currentBeat
        let secondsToNextWholeBeat = fractionalRemaining * secondsPerBeat
        if waitForDownbeat {
            let beatsToNextMeasureStart = Double(4 - beatInMeasure)
            let seconds = secondsToNextWholeBeat + (beatsToNextMeasureStart - 1.0) * secondsPerBeat
            return date.addingTimeInterval(max(seconds, 0.05))
        }
        let beatsUntilNext: Double
        switch beatInMeasure {
        case 0: beatsUntilNext = 2
        case 1: beatsUntilNext = 1
        case 2: beatsUntilNext = 2
        case 3: beatsUntilNext = 1
        default: beatsUntilNext = 2
        }
        let secondsToTarget = secondsToNextWholeBeat + (beatsUntilNext - 1.0) * secondsPerBeat
        return date.addingTimeInterval(max(secondsToTarget, 0.05))
    }

    // MARK: - Navigation helpers

    func shiftFretSpan(by delta: Int) {
        guard delta != 0 else { return }
        withAnimation(.easeInOut(duration: 0.5)) {
            currentFretStart = min(max(currentFretStart + delta, minFretOffset), maxFretOffset)
        }
    }

    func shiftWindow(by delta: Int) {
        let proposed = currentWindowRow + delta
        let clamped = min(max(proposed, 0), 7)
        guard clamped != currentWindowRow else { return }
        withAnimation(.easeInOut(duration: 0.45)) {
            currentWindowRow = clamped
        }
    }

    func nextThumbState(after state: ThumbGlowState) -> ThumbGlowState {
        switch state {
        case .neutral: return .green
        case .orange: return .green
        case .green: return .red
        case .red: return .neutral
        }
    }

    // MARK: - Autoplay

    func handleMaestroAutoPlayIfNeeded(currentDate: Date) {
        guard autoPlayEnabled,
              !isCodeScreensaverMode,
              !startupSequenceActivated,
              !isResolvingAnswer,
              !isRoundPaused
        else {
            if !autoPlayEnabled {
                autoPlayNextDate = nil
            }
            return
        }

        guard let nextDate = autoPlayNextDate, currentDate >= nextDate else { return }

        // If we're more than one beat late, the date is stale — reschedule cleanly
        let oneBeat = 60.0 / Double(max(audioSettings.startingBPM, 40))
        if currentDate.timeIntervalSince(nextDate) > oneBeat {
            autoPlayNextDate = nextOnAndThreeBeatDate(after: currentDate)
            return
        }

        // Submit the correct answer
        isAutoPlayTriggered = true
        submitAnswer(correctAnswerSide, force: true)
        isAutoPlayTriggered = false
        autoPlayNextDate = nextOnAndThreeBeatDate(after: currentDate)
    }

    // MARK: - Game session

    func startGameFromBeginning(animateNeckSlideFromStartup: Bool = false) {
        currentRound = playStartingFret
        applyTempoForRound(currentRound)
        roundStringIndex = 0
        repetitionsRemainingAtFret = playInfiniteRepetitions ? Int.max : max(playRepetitions, 1)
        isDescendingPhase = isPhaseDescending
        if animateNeckSlideFromStartup {
            // Mirror BeginnerGameplayView: jump nut/neck off-screen, then animate slide-in.
            currentFretStart = isDescendingPhase ? maxFretOffset : minFretOffset
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.78)) {
                    currentFretStart = self.currentRound
                }
            }
        }
        bankDollars = 0
        displayedBankDollars = 0
        walletDollars = 0
        currentPromptStrings = [1]
        activePickedStringNumbers = [1]
        answeredNotesByStringAtCurrentFret = [:]
        beatCountInRemaining = 4
        nextBeatTickDate = nil
        leftThumbState = .neutral
        rightThumbState = .neutral
        activeAnswerFeedback = nil
        gameplayMenuExpanded = false
        developerPromptText = ""
        currentCorrectNote = ""
        lastResolvedCorrectNote = nil
        lastResolvedCorrectString = nil
        beatLightFlashOn = false
        beatLightLastProcessedBeat = nil
        autoPlayNextDate = nil
        isResolvingAnswer = false
        streakMeterLitSegments = 0
        streakMeterFailureActive = false
        streakMultiplier = 1
        streakMultiplierFlashText = nil
        midiEngine.setBassTransposeSemitones(0)
        prepareCurrentQuestion()
    }

    // MARK: - Answer submission

    func submitAnswer(_ side: AnswerSide, force: Bool = false) {
        if isCodeScreensaverMode {
            if !startupSequenceActivated {
                startupSequenceActivated = true
                startupSequenceStartDate = .now
                startupSequenceElapsed = 0
                questionBoxIntroProgress = 0
                return
            }

            guard !isLaunchTransitionAnimating else { return }

            isLaunchTransitionAnimating = true
            launchTileScale = 1
            launchTileOpacity = 1
            // Pre-position neck off-screen so it isn't briefly visible at its previous fret while the logo fades.
            currentFretStart = isPhaseDescending ? maxFretOffset : minFretOffset
            withAnimation(.easeIn(duration: AnimationDurations.launchTransition)) {
                launchTileScale = 0.1
                launchTileOpacity = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + AnimationDurations.launchTransition) {
                self.isCodeScreensaverMode = false
                self.startupSequenceActivated = false
                self.startupSequenceElapsed = 0
                self.startupSpeechPhase = .idle
                self.startGameFromBeginning(animateNeckSlideFromStartup: true)
                self.syncMaestroBackingTrack()
                self.isLaunchTransitionAnimating = false
                self.launchTileScale = 1
                self.launchTileOpacity = 1
                withAnimation(.easeOut(duration: 0.6)) {
                    self.questionBoxIntroProgress = 1
                }
            }
            return

        }

        guard force || !isResolvingAnswer else { return }
        isResolvingAnswer = true

        let isCorrect = side == correctAnswerSide
        if isCorrect {
            withAnimation(.none) {
                leftThumbState = .green
                rightThumbState = .green
                activeAnswerFeedback = .green
            }
            let totalSegments = 60 // 20 columns × 3 rows
            streakMeterFailureActive = false
            let prevLit = streakMeterLitSegments % totalSegments
            let newLit = prevLit + 1
            streakMeterLitSegments = newLit == totalSegments ? 0 : newLit

            // Multiplier thresholds — trigger on crossing 25 and 50
            if newLit == 25 {
                streakMultiplier = 2
                streakMultiplierFlashText = "2× MULTIPLIER"
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                    if self.streakMultiplierFlashText == "2× MULTIPLIER" { self.streakMultiplierFlashText = nil }
                }
            } else if newLit == 50 {
                streakMultiplier = 3
                streakMultiplierFlashText = "3× MULTIPLIER"
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                    if self.streakMultiplierFlashText == "3× MULTIPLIER" { self.streakMultiplierFlashText = nil }
                }
            }
            lastResolvedCorrectNote = currentCorrectNote
            lastResolvedCorrectString = currentPromptStrings.first
            // Track correctly answered notes per string at current fret
            for stringNumber in currentPromptStrings {
                answeredNotesByStringAtCurrentFret[stringNumber] = currentCorrectNote
            }
            for (index, stringNumber) in currentPromptStrings.enumerated() {
                let delay = Double(index) * 0.035
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self.guitarNoteEngine.play(string: stringNumber, fret: max(self.currentRound, 0), velocity: AudioVelocity.full)
                }
            }
        } else {
            withAnimation(.none) {
                leftThumbState = .red
                rightThumbState = .red
                activeAnswerFeedback = .red
            }
        }

        // Capture autoplay state before delay since flag gets reset
        let wasAutoPlayTriggered = isAutoPlayTriggered
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            self.leftThumbState = .neutral
            self.rightThumbState = .neutral
            if isCorrect {
                self.advanceGame(afterCorrectAnswer: true, fromAutoPlay: wasAutoPlayTriggered)
            } else {
                self.advanceGame(afterCorrectAnswer: false, fromAutoPlay: wasAutoPlayTriggered)
            }
        }
    }

    // MARK: - Transport handlers

    func handleMaestroStartButton() {
        if isCodeScreensaverMode {
            if !startupSequenceActivated {
                startupSequenceActivated = true
                startupSequenceStartDate = .now
                startupSequenceElapsed = 0
                questionBoxIntroProgress = 0
                return
            }
            guard !isLaunchTransitionAnimating else { return }
            isLaunchTransitionAnimating = true
            launchTileScale = 1
            launchTileOpacity = 1
            // Pre-position neck off-screen so it isn't briefly visible at its previous fret while the logo fades.
            currentFretStart = isPhaseDescending ? maxFretOffset : minFretOffset
            withAnimation(.easeIn(duration: AnimationDurations.launchTransition)) {
                launchTileScale = 0.1
                launchTileOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + AnimationDurations.launchTransition) {
                self.isCodeScreensaverMode = false
                self.startupSequenceActivated = false
                self.startupSequenceElapsed = 0
                self.startupSpeechPhase = .idle
                self.startGameFromBeginning(animateNeckSlideFromStartup: true)
                self.isLaunchTransitionAnimating = false
                self.launchTileScale = 1
                self.launchTileOpacity = 1
                self.isRoundPaused = false
                self.transportStoppedForResume = false
                self.syncMaestroBackingTrack()
                withAnimation(.easeOut(duration: 0.6)) {
                    self.questionBoxIntroProgress = 1
                }
            }
            return
        }

        if transportStoppedForResume {
            isRoundPaused = false
            transportStoppedForResume = false
            nextBeatTickDate = nil
            beatLightLastProcessedBeat = nil
            syncMaestroBackingTrack(allowResumeFromPause: true)
            return
        }

        if !isCodeScreensaverMode {
            handleMaestroResetButton()
        }
    }

    func handleMaestroStopButton() {
        guard !isCodeScreensaverMode, !isRoundPaused else { return }
        isRoundPaused = true
        transportStoppedForResume = true
        nextBeatTickDate = nil
        beatPulseActive = false
        beatLightFlashOn = false
        beatLightLastProcessedBeat = nil
        midiEngine.pause()
    }

    func handleMaestroResetButton() {
        resetButtonPressed = true
        DispatchQueue.main.asyncAfter(deadline: .now() + AnimationDurations.resetDelay) {
            self.resetButtonPressed = false
        }

        isRoundPaused = false
        transportStoppedForResume = false
        nextBeatTickDate = nil
        beatPulseActive = false
        midiEngine.stop()
        isCodeScreensaverMode = true
        startupSequenceActivated = true
        startupSequenceStartDate = .now
        startupSequenceElapsed = 0
        startupSpeechPhase = .pendingArmed
        questionBoxIntroProgress = 0
        isLaunchTransitionAnimating = false
        launchTileScale = 1
        launchTileOpacity = 1
        startGameFromBeginning()
        // Note: startGameFromBeginning now handles the transpose restart
        beatLightFlashOn = false
        beatLightLastProcessedBeat = nil
        autoPlayNextDate = nil
        autoPlayEnabled = false
    }

    // MARK: - Backing track

    func syncMaestroBackingTrack(allowResumeFromPause: Bool = false) {
        if availableBackingTracks.isEmpty {
            availableBackingTracks = BackingTrack.discoverBundledTracks()
        }
        guard !availableBackingTracks.isEmpty else {
            midiEngine.stop()
            return
        }
        audioSettings.selectInitialBackingTrackIfNeeded(from: availableBackingTracks)
        guard let selectedTrackID = audioSettings.selectedBackingTrackID,
              let selectedTrack = availableBackingTracks.first(where: { $0.id == selectedTrackID }),
              let trackURL = selectedTrack.resourceURL() else {
            midiEngine.stop()
            return
        }
        if allowResumeFromPause {
            midiEngine.resume()
            return
        }
        if midiEngine.isPlaying, midiEngine.activeURL == trackURL {
            return
        }
        midiEngine.play(url: trackURL, title: selectedTrack.title, loop: true)
    }

    // MARK: - Game progression

    func advanceGame(afterCorrectAnswer isCorrect: Bool, fromAutoPlay: Bool = false) {
        if !isCorrect {
            restartAtCurrentFret()
            return
        }

        // Only award points for player correct answers, not autoplay
        if !fromAutoPlay {
            let payout = payoutForRound(currentRound) * streakMultiplier
            bankDollars += payout
            displayedBankDollars = bankDollars
            walletDollars = bankDollars
            balanceDollars += payout
        }

        // Advance to next string in round
        if roundStringIndex < activeStringOrder.count - 1 {
            roundStringIndex += 1
        } else {
            // Pass through all strings complete — decrement repetition counter
            roundStringIndex = 0
            if playInfiniteRepetitions {
                // Infinite mode: never decrement, stay at current fret
            } else {
                repetitionsRemainingAtFret -= 1
                if repetitionsRemainingAtFret <= 0 {
                    repetitionsRemainingAtFret = max(playRepetitions, 1)
                    // Clear answered notes when neck shifts to new fret
                    answeredNotesByStringAtCurrentFret = [:]
                    if !isPhaseDescending {
                        if currentRound < (playEnableHighFrets ? 19 : 12) {
                            currentRound += 1
                        } else {
                            // At upper boundary - reverse direction
                            isDescendingPhase = true
                            playDirectionRawValue = LessonDirection.descending.rawValue
                            currentRound = (playEnableHighFrets ? 19 : 12) - 1
                        }
                    } else {
                        if currentRound > 0 {
                            currentRound -= 1
                        } else {
                            // At lower boundary - reverse direction
                            isDescendingPhase = false
                            playDirectionRawValue = LessonDirection.ascending.rawValue
                            currentRound = 1
                        }
                    }
                    // Immediate bass transpose
                    midiEngine.setBassTransposeSemitones(max(currentRound, 0) % 12)
                    applyTempoForRound(currentRound)
                    // Immediate neck shift with animation
                    withAnimation(.easeInOut(duration: 0.9)) {
                        currentFretStart = max(currentRound, 0)
                    }
                }
            }
        }
        isResolvingAnswer = false
        prepareCurrentQuestion()
    }

    func prepareCurrentQuestion() {
        if roundStringIndex == 0 { answeredNotesByStringAtCurrentFret = [:] }
        let targetString = activeStringOrder[min(max(roundStringIndex, 0), activeStringOrder.count - 1)]
        currentPromptStrings = [targetString]

        let noteString = currentPromptStrings.first ?? targetString
        let fret = max(currentRound, 0)
        let useFlats = maestroUsesFlats
        let correctNote = noteName(forString: noteString, fret: fret, useFlats: useFlats)
        let incorrectNote = randomIncorrectNote(excluding: correctNote, excludingLast: lastResolvedCorrectNote, useFlats: useFlats)

        let correctOnLeft = Bool.random()

        if correctOnLeft {
            leftChoiceNote = correctNote
            rightChoiceNote = incorrectNote
        } else {
            leftChoiceNote = incorrectNote
            rightChoiceNote = correctNote
        }

        correctAnswerSide = correctOnLeft ? .left : .right
        currentCorrectNote = correctNote

        // Include both current prompt string and previously answered strings at current fret
        let answeredStrings = Array(answeredNotesByStringAtCurrentFret.keys)
        activePickedStringNumbers = answeredStrings + currentPromptStrings
        currentQuestionIsAccidental = guitarNoteContainsAccidental(correctNote)
        activeAnswerFeedback = nil

        // Cache labels so they stay in sync with the question
        cachedFretStatusLabel = "FRET \(fret)"
        cachedStringStatusLabel = "STRING \(currentPromptStrings[0])"

        if audioEngineEnabled && speakGameplayPrompts {
            let promptSpoken = currentPromptStrings.count > 1
                ? currentPromptStrings.map { "string \($0)" }.joined(separator: " and ")
                : "string \(targetString)"
            audioEngine.playNotePrompt(promptSpoken, volume: stringVolume)
        }

        withAnimation(.easeInOut(duration: 0.9)) {
            currentFretStart = fret
        }
    }

    func payoutForRound(_ round: Int) -> Int {
        return 2
    }

    func restartAtCurrentFret() {
        roundStringIndex = 0
        repetitionsRemainingAtFret = playInfiniteRepetitions ? Int.max : max(playRepetitions, 1)
        answeredNotesByStringAtCurrentFret = [:]
        activePickedStringNumbers = [1]
        currentPromptStrings = [1]
        activeAnswerFeedback = nil
        isResolvingAnswer = false
        streakMultiplier = 1
        streakMultiplierFlashText = nil
        streakMeterFailureActive = true
        streakMeterLitSegments = 60 // 20 columns × 3 rows — all lit red
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            self.streakMeterFailureActive = false
            self.streakMeterLitSegments = 0
        }
        prepareCurrentQuestion()
    }

    // MARK: - Note helpers

    func noteName(forString string: Int, fret: Int, useFlats: Bool) -> String {
        guitarNoteName(forString: string, fret: fret, useFlats: useFlats)
    }

    func randomIncorrectNote(excluding correct: String, excludingLast lastCorrect: String?, useFlats: Bool) -> String {
        let source = useFlats ? chromaticFlats : chromaticSharps
        let correctIsAccidental = guitarNoteContainsAccidental(correct)
        let pool = source.filter { note in
            note != correct &&
            guitarNoteContainsAccidental(note) == correctIsAccidental &&
            note != lastCorrect
        }
        return pool.randomElement() ?? (correctIsAccidental ? "C#" : "C")
    }

    // MARK: - Menu / fretboard / audio

    func handleGameplayMenuSelection(_ option: GameplayMenuOption) {
        gameplayMenuExpanded = false
        if !isCodeScreensaverMode && !isRoundPaused {
            handleMaestroStopButton()
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

    func handleFretboardButtonPress() {
        showFretboardGuide.toggle()
        showDeveloperPrompt(showFretboardGuide ? "Fretboard guide ON" : "Fretboard guide OFF")
    }

    // MARK: - Startup speech

    func handleStartupSpeech(for phase: MaestroStartupSequenceView.Phase) {
        guard audioEngineEnabled else { return }
        switch phase {
        case .armed:
            if startupSpeechPhase == .pendingArmed {
                speakStartup("Memorization Sequence Armed")
                startupSpeechPhase = .idle
            }
        }
    }

    func speakStartup(_ phrase: String) {
        audioEngine.speakStartupAlert(phrase, volume: stringVolume)
    }

    // MARK: - Developer prompt

    func showDeveloperPrompt(_ text: String) {
        developerPromptText = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            if self.developerPromptText == text {
                self.developerPromptText = ""
            }
        }
    }
}

// MARK: - MaestroGameplayView UI Helpers

extension MaestroGameplayView {
    func textWidth(for text: String, font: UIFont) -> CGFloat {
        let attributes = [NSAttributedString.Key.font: font]
        return ceil(text.size(withAttributes: attributes).width)
    }
}
