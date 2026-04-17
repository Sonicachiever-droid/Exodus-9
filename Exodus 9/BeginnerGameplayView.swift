import SwiftUI
import Combine

// MARK: - Beginner Gameplay View (thin coordinator — ~200 lines)
// All game logic lives in BeginnerGameEngine.
// This view owns layout, the timer, and passes actions into the engine.

struct BeginnerGameplayView: View {
    // MARK: - Callbacks & Settings from parent
    let onMenuSelection: (GameplayMenuOption) -> Void
    @Binding var playStartingFret: Int
    @Binding var playRepetitions: Int
    @Binding var playDirectionRawValue: String
    @Binding var playEnableHighFrets: Bool
    @Binding var playLessonStyle: String
    @Binding var walletDollars: Int
    @Binding var balanceDollars: Int

    // MARK: - Engine
    @State private var engine = BeginnerGameEngine()

    // MARK: - MIDI & Audio
    @State private var midiEngine = SimpleMIDIEngine()
    @State private var guitarNoteEngine = GuitarNoteEngine()
    @State private var audioSettings = AudioSettings()
    @State private var availableBackingTracks: [BackingTrack] = []
    @State private var isBackingTrackPlaying: Bool = false

    // MARK: - UI-only state
    @State private var gameplayMenuExpanded: Bool = false
    @State private var showFretboardGuide: Bool = false

    // MARK: - Timer
    let timer = Timer.publish(every: 0.033, on: .main, in: .common).autoconnect()

    // MARK: - Computed: startup state for button glow
    private var startupStateArmedAndVisible: Bool {
        guard engine.isScreensaverMode, engine.startupSequenceActivated else { return false }
        let s = StartupSequenceView.state(
            for: engine.startupSequenceElapsed,
            showFullSequence: engine.state.currentPhaseNumber == 1,
            armedText: engine.armedText
        )
        return s.phase == .armed && s.isVisible
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background
                Color.black.ignoresSafeArea()

                // Main console area
                VStack(spacing: 0) {
                    // Console display
                    ZStack {
                        Color.black

                        if engine.isScreensaverMode && engine.startupSequenceActivated {
                            StartupSequenceView(
                                elapsed: engine.startupSequenceElapsed,
                                showFullSequence: engine.state.currentPhaseNumber == 1,
                                armedText: engine.armedText
                            )
                            .padding(.horizontal, 24)
                        } else {
                            BeginnerConsoleView(
                                engine: engine,
                                width: geo.size.width,
                                height: geo.size.height * 0.28
                            )
                        }
                    }
                    .frame(height: geo.size.height * 0.28)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )

                    // Button panel area
                    ZStack {
                        Color(white: 0.07)

                        BeginnerButtonPanelView(
                            engine: engine,
                            containerWidth: geo.size.width,
                            containerHeight: geo.size.height * 0.50,
                            buttonCenterY: geo.size.height * 0.50 * 0.50,
                            transportCenterY: geo.size.height * 0.50 * 0.88,
                            lowerScreenWidth: geo.size.width * 0.30,
                            lowerScreenHeight: geo.size.height * 0.50 * 0.22,
                            isArmedAndVisible: startupStateArmedAndVisible,
                            noteName: { string, fret, flats in
                                guitarNoteName(forString: string, fret: fret, useFlats: flats)
                            }
                        )
                    }
                    .frame(height: geo.size.height * 0.50)
                    .clipped()

                    // Control plate
                    ZStack {
                        Color(white: 0.05)

                        BeginnerControlPlateView(
                            engine: engine,
                            onStart: { handleStart() },
                            onReset: { handleReset() }
                        )
                        .padding(.horizontal, 12)
                    }
                    .frame(height: geo.size.height * 0.12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
                }
            }
        }
        .onAppear { handleAppear() }
        .onReceive(timer) { date in
            syncEngineSettings()
            engine.tick(date: date, midiEngine: midiEngine)
            syncBackingTrack()
        }
    }

    // MARK: - Action Handlers

    private func handleStart() {
        if engine.state.phaseCompletedMessagePending {
            engine.state.pendingPhaseCompletedAutoAdvanceDate = nil
            engine.state.phaseCompletedMessagePending = false
            engine.state.phaseCompletedMessageStartBeat = nil
            engine.advanceToNextPhaseArmedState(midiEngine: midiEngine)
            return
        }

        if engine.isScreensaverMode && engine.startupSequenceActivated {
            guard !engine.isLaunchTransitionAnimating else { return }
            engine.isLaunchTransitionAnimating = true
            engine.launchTileScale = 1
            engine.launchTileOpacity = 1
            withAnimation(.easeIn(duration: 0.4725)) {
                engine.launchTileScale = 0.1
                engine.launchTileOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4725) {
                engine.startRoundAfterLaunch()
                syncBackingTrack()
            }
            return
        }

        engine.handleRoundStart()
        syncBackingTrack()
    }

    private func handleReset() {
        engine.handleReset(midiEngine: midiEngine)
        syncBackingTrack()
    }

    // MARK: - Setup & Sync

    private func handleAppear() {
        availableBackingTracks = BackingTrack.discoverBundledTracks()
        audioSettings.selectInitialBackingTrackIfNeeded(from: availableBackingTracks)
        guitarNoteEngine.configure(
            preset: audioSettings.guitarTonePreset,
            reverbLevel: audioSettings.reverbLevel,
            delayLevel: audioSettings.delayLevel
        )
        syncEngineSettings()
        syncBackingTrack()
    }

    private func syncEngineSettings() {
        engine.lessonStyle = LessonStyle(rawValue: playLessonStyle) ?? .sequential
        engine.bpm = 120
        engine.useFlats = false
        engine.playRepetitions = playRepetitions
        engine.startingFret = playStartingFret
    }

    private func syncBackingTrack() {
        guard let trackID = audioSettings.selectedBackingTrackID,
              let track = availableBackingTracks.first(where: { $0.id == trackID }) else {
            midiEngine.stop()
            isBackingTrackPlaying = false
            return
        }
        if engine.isRoundArmed || engine.isScreensaverMode || engine.isRoundPaused {
            if midiEngine.isPlaying { midiEngine.stop() }
            isBackingTrackPlaying = false
            return
        }
        guard let url = track.resourceURL() else { return }
        if !midiEngine.isPlaying {
            midiEngine.play(url: url, title: track.title, loop: true)
            isBackingTrackPlaying = midiEngine.isPlaying
        }
    }
}
