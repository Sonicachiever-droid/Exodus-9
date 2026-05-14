import AVFoundation
import Combine

// MARK: - Unified Audio Engine
// Single AVAudioEngine with guitar sampler + MIDI samplers on one mixer.
// Fixes: two-engine clipping (A1), bass > unity (A2), outputVolume abuse (A3), session conflict (A5).

final class SharedAudioEngine: ObservableObject {

    static let shared = SharedAudioEngine()

    // MARK: - Single shared engine

    private let engine = AVAudioEngine()

    // MARK: - Guitar sampler chain

    private let guitarSampler = AVAudioUnitSampler()
    private let delay = AVAudioUnitDelay()
    private let reverb = AVAudioUnitReverb()

    // MARK: - MIDI / backing track chain

    private let sequencer: AVAudioSequencer
    private let keysSampler = AVAudioUnitSampler()
    private let bassSampler = AVAudioUnitSampler()
    private let drumsSampler = AVAudioUnitSampler()

    // MARK: - Guitar state

    private var activeMIDINote: UInt8?
    private var notePlaybackToken: UInt64 = 0
    private var chordPlaybackToken: UInt64 = 0
    private var toneConfiguration = ToneConfiguration(
        preset: .acoustic,
        reverbLevel: .off,
        delayLevel: .off
    )

    private let openMIDINotesByString: [Int: Int] = GuitarConstants.openMIDINotesByString

    private let instrumentByPreset: [GuitarTonePreset: InstrumentDescriptor] = [
        .acoustic: InstrumentDescriptor(bundledResourceName: "guitar_acoustic", bundledFileExtension: "sf2", program: GuitarConstants.programAcoustic),
        .electricClean: InstrumentDescriptor(bundledResourceName: "guitar_clean", bundledFileExtension: "sf2", program: GuitarConstants.programElectricClean),
        .electricDirty: InstrumentDescriptor(bundledResourceName: "guitar_dirty", bundledFileExtension: "sf2", program: GuitarConstants.programElectricDirty),
    ]

    // MARK: - MIDI state

    @Published var isPlaying: Bool = false
    @Published var currentTrackTitle: String = ""

    private(set) var currentURL: URL?
    var activeURL: URL? { currentURL }
    private var isLooping: Bool = true
    private var loopTimer: Timer?
    private let loopLengthInBeats: TimeInterval = AudioConstants.loopLengthInBeats
    private var bassTransposeSemitones: Int = 0
    private var pausedPositionInBeats: TimeInterval?
    private var isStopped: Bool = false

    // MARK: - Private types

    private struct ToneConfiguration: Equatable {
        let preset: GuitarTonePreset
        let reverbLevel: AudioEffectLevel
        let delayLevel: AudioEffectLevel
    }

    private struct InstrumentDescriptor {
        let bundledResourceName: String
        let bundledFileExtension: String
        let program: UInt8
    }

    // MARK: - Init

    init() {
        self.sequencer = AVAudioSequencer(audioEngine: engine)

        // Attach guitar chain
        engine.attach(guitarSampler)
        engine.attach(delay)
        engine.attach(reverb)
        engine.connect(guitarSampler, to: delay, format: nil)
        engine.connect(delay, to: reverb, format: nil)
        engine.connect(reverb, to: engine.mainMixerNode, format: nil)

        // Attach MIDI samplers
        engine.attach(keysSampler)
        engine.attach(bassSampler)
        engine.attach(drumsSampler)
        engine.connect(keysSampler, to: engine.mainMixerNode, format: nil)
        engine.connect(bassSampler, to: engine.mainMixerNode, format: nil)
        engine.connect(drumsSampler, to: engine.mainMixerNode, format: nil)

        // FIX A2: Bass volume capped below unity. All samplers gain-staged safely.
        keysSampler.volume = AudioConstants.keysVolume
        bassSampler.volume = AudioConstants.bassVolume
        drumsSampler.volume = AudioConstants.drumsVolume

        // FIX A3: Master volume set ONCE — never mutated per-note.
        engine.mainMixerNode.outputVolume = AudioConstants.masterVolume

        configureGuitarEffects()
        loadGuitarInstrument(for: toneConfiguration.preset)
        loadMIDISamplers()
        startEngineIfNeeded()
    }

    // MARK: - Guitar Note API (matches GuitarNoteEngine interface)

    func stopAll() {
        notePlaybackToken &+= 1
        chordPlaybackToken &+= 1
        if let activeMIDINote {
            guitarSampler.stopNote(activeMIDINote, onChannel: 0)
            self.activeMIDINote = nil
        }
    }

    func play(string: Int, fret: Int, velocity: Float = AudioConstants.defaultNoteVelocity) {
        guard let openMIDINote = openMIDINotesByString[string] else { return }
        let midiNote = openMIDINote + max(fret, 0)
        play(midiNote: midiNote, velocity: velocity)
    }

    func configure(
        preset: GuitarTonePreset,
        reverbLevel: AudioEffectLevel,
        delayLevel: AudioEffectLevel
    ) {
        let newConfiguration = ToneConfiguration(
            preset: preset,
            reverbLevel: reverbLevel,
            delayLevel: delayLevel
        )
        guard newConfiguration != toneConfiguration else { return }
        let presetChanged = newConfiguration.preset != toneConfiguration.preset
        toneConfiguration = newConfiguration
        configureGuitarEffects()
        if presetChanged {
            stopAll()
            loadGuitarInstrument(for: preset)
        }
    }

    func play(midiNote: Int, velocity: Float = AudioConstants.defaultNoteVelocity) {
        let clampedMIDINote = min(max(midiNote, GuitarConstants.midiNoteMin), GuitarConstants.midiNoteMax)
        startEngineIfNeeded()
        if let activeMIDINote {
            guitarSampler.stopNote(activeMIDINote, onChannel: 0)
        }
        // FIX A3: Do NOT set engine.mainMixerNode.outputVolume here.
        // Use MIDI velocity only for dynamics.
        let adjustedVelocity = effectiveVelocity(for: toneConfiguration.preset, requested: velocity)
        let noteValue = UInt8(clampedMIDINote)
        let velocityValue = UInt8(max(1, min(Int(adjustedVelocity * 127.0), 127)))
        guitarSampler.startNote(noteValue, withVelocity: velocityValue, onChannel: 0)
        activeMIDINote = noteValue
        notePlaybackToken &+= 1
        let playbackToken = notePlaybackToken
        let releaseDelay = noteLength(for: toneConfiguration.preset)

        DispatchQueue.main.asyncAfter(deadline: .now() + releaseDelay) { [weak self] in
            guard let self else { return }
            guard self.notePlaybackToken == playbackToken else { return }
            guard self.activeMIDINote == noteValue else { return }
            self.guitarSampler.stopNote(noteValue, onChannel: 0)
            self.activeMIDINote = nil
        }
    }

    @discardableResult
    func playChord(midiNotes: [Int], velocity: Float = AudioConstants.defaultNoteVelocity, sustainMultiplier: Double = 1.0) -> TimeInterval {
        let clampedNotes = Array(Set(midiNotes.map { min(max($0, GuitarConstants.midiNoteMin), GuitarConstants.midiNoteMax) })).sorted()
        guard !clampedNotes.isEmpty else { return 0 }

        startEngineIfNeeded()
        if let activeMIDINote {
            guitarSampler.stopNote(activeMIDINote, onChannel: 0)
            self.activeMIDINote = nil
        }

        let adjustedVelocity = effectiveVelocity(for: toneConfiguration.preset, requested: velocity)
        let velocityValue = UInt8(max(1, min(Int(adjustedVelocity * 127.0), 127)))
        let noteValues = clampedNotes.map(UInt8.init)
        for noteValue in noteValues {
            guitarSampler.startNote(noteValue, withVelocity: velocityValue, onChannel: 0)
        }

        chordPlaybackToken &+= 1
        let playbackToken = chordPlaybackToken
        let effectiveSustain = effectiveSustainMultiplier(for: toneConfiguration.preset, requested: sustainMultiplier)
        let releaseDelay = noteLength(for: toneConfiguration.preset) * effectiveSustain
        DispatchQueue.main.asyncAfter(deadline: .now() + releaseDelay) { [weak self] in
            guard let self else { return }
            guard self.chordPlaybackToken == playbackToken else { return }
            for noteValue in noteValues {
                self.guitarSampler.stopNote(noteValue, onChannel: 0)
            }
        }
        return releaseDelay
    }

    // MARK: - MIDI / Backing Track API (matches SimpleMIDIEngine interface)

    func play(url: URL, title: String = "", loop: Bool = true) {
        stop()

        currentURL = url
        currentTrackTitle = title.isEmpty ? url.lastPathComponent : title
        isLooping = loop
        isStopped = false
        pausedPositionInBeats = nil

        do {
            try sequencer.load(from: url)
            routeTracksToSamplers()
            applyBassTranspose()

            if loop {
                configureTrackLooping()
            }

            sequencer.prepareToPlay()
            try sequencer.start()

            DispatchQueue.main.async {
                self.isPlaying = true
            }

            #if DEBUG
            print("[SharedAudioEngine] Playing: \(currentTrackTitle) (looping: \(loop))")
            #endif

        } catch {
            #if DEBUG
            print("[SharedAudioEngine] Failed to play: \(error)")
            #endif
        }
    }

    func setBassTransposeSemitones(_ semitones: Int) {
        bassTransposeSemitones = semitones
        applyBassTranspose()
    }

    func pause() {
        guard sequencer.isPlaying else { return }
        pausedPositionInBeats = max(sequencer.currentPositionInBeats, 0)
        sequencer.stop()

        DispatchQueue.main.async {
            self.isPlaying = false
        }
        #if DEBUG
        print("[SharedAudioEngine] Paused at beat \(pausedPositionInBeats ?? 0)")
        #endif
    }

    func resume() {
        guard !sequencer.isPlaying else { return }
        guard currentURL != nil else { return }

        do {
            if let pausedPositionInBeats {
                sequencer.currentPositionInBeats = max(pausedPositionInBeats, 0)
            }
            try sequencer.start()

            DispatchQueue.main.async {
                self.isPlaying = true
            }
            #if DEBUG
            print("[SharedAudioEngine] Resumed at beat \(sequencer.currentPositionInBeats)")
            #endif
        } catch {
            #if DEBUG
            print("[SharedAudioEngine] Failed to resume: \(error)")
            #endif
        }
    }

    func stop() {
        isStopped = true
        sequencer.stop()
        sequencer.currentPositionInBeats = 0
        pausedPositionInBeats = nil

        DispatchQueue.main.async {
            self.isPlaying = false
        }
        #if DEBUG
        print("[SharedAudioEngine] Stopped")
        #endif
    }

    func setTempo(bpm: Double) {
        sequencer.rate = Float(bpm / 120.0)
        #if DEBUG
        print("[SharedAudioEngine] Tempo changed to \(bpm) BPM")
        #endif
    }

    func currentBeatPosition() -> Double {
        max(sequencer.currentPositionInBeats, 0)
    }

    func setLooping(_ looping: Bool) {
        isLooping = looping
        for track in sequencer.tracks {
            track.numberOfLoops = looping ? -1 : 1
            track.isLoopingEnabled = looping
        }
        #if DEBUG
        print("[SharedAudioEngine] Looping set to: \(looping)")
        #endif
    }

    func muteTrack0() {
        if sequencer.tracks.count > 0 { sequencer.tracks[0].isMuted = true }
    }

    func muteTrack1() {
        if sequencer.tracks.count > 1 { sequencer.tracks[1].isMuted = true }
    }

    func muteTrack2() {
        if sequencer.tracks.count > 2 { sequencer.tracks[2].isMuted = true }
    }

    func muteTrack3() {
        if sequencer.tracks.count > 3 { sequencer.tracks[3].isMuted = true }
    }

    func unmuteAllTracks() {
        for track in sequencer.tracks { track.isMuted = false }
    }

    // MARK: - Guitar internals

    private func loadGuitarInstrument(for preset: GuitarTonePreset) {
        guard let descriptor = instrumentByPreset[preset] else { return }

        let soundFontCandidates: [URL?] = [
            Bundle.main.url(forResource: "GeneralUser GS v1.472", withExtension: "sf2", subdirectory: "GeneralUser GS 1.472"),
            Bundle.main.url(forResource: "GeneralUser GS v1.472", withExtension: "sf2"),
            Bundle.main.url(forResource: descriptor.bundledResourceName, withExtension: descriptor.bundledFileExtension),
            Bundle.main.url(forResource: descriptor.bundledResourceName, withExtension: "dls")
        ]

        for candidate in soundFontCandidates {
            guard let instrumentURL = candidate else { continue }
            do {
                try guitarSampler.loadSoundBankInstrument(
                    at: instrumentURL,
                    program: descriptor.program,
                    bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                    bankLSB: 0
                )
                #if DEBUG
                print("[SharedAudioEngine] Loaded guitar sounds from \(instrumentURL.lastPathComponent)")
                #endif
                // Prime the sampler to avoid first-note glitch
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    guard let self else { return }
                    self.guitarSampler.startNote(40, withVelocity: 1, onChannel: 0)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        self.guitarSampler.stopNote(40, onChannel: 0)
                    }
                }
                return
            } catch {
                #if DEBUG
                print("[SharedAudioEngine] Failed loading \(instrumentURL.lastPathComponent) - \(error)")
                #endif
            }
        }

        for fallbackURL in fallbackSoundBankURLs() {
            do {
                try guitarSampler.loadSoundBankInstrument(
                    at: fallbackURL,
                    program: descriptor.program,
                    bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                    bankLSB: 0
                )
                #if DEBUG
                print("[SharedAudioEngine] Using system sound bank fallback")
                #endif
                return
            } catch {
                #if DEBUG
                print("[SharedAudioEngine] Failed fallback sound bank load - \(error)")
                #endif
            }
        }
    }

    private func configureGuitarEffects() {
        delay.bypass = toneConfiguration.delayLevel == .off
        delay.wetDryMix = wetDryMix(for: toneConfiguration.delayLevel)
        delay.delayTime = delayTime(for: toneConfiguration.preset)
        delay.feedback = feedback(for: toneConfiguration.delayLevel, preset: toneConfiguration.preset)
        delay.lowPassCutoff = toneConfiguration.preset == .electricDirty ? 8_500 : 11_500

        reverb.loadFactoryPreset(reverbPreset(for: toneConfiguration.preset))
        reverb.wetDryMix = wetDryMix(for: toneConfiguration.reverbLevel)
        reverb.bypass = toneConfiguration.reverbLevel == .off
    }

    private func wetDryMix(for level: AudioEffectLevel) -> Float {
        switch level {
        case .off: return 0
        case .low: return 18
        case .medium: return 32
        case .high: return 48
        }
    }

    private func feedback(for level: AudioEffectLevel, preset: GuitarTonePreset) -> Float {
        let base: Float
        switch level {
        case .off:    base = AudioConstants.feedbackOff
        case .low:    base = AudioConstants.feedbackLow
        case .medium: base = AudioConstants.feedbackMedium
        case .high:   base = AudioConstants.feedbackHigh
        }
        return preset == .electricDirty ? base + AudioConstants.electricDirtyFeedbackBoost : base
    }

    private func delayTime(for preset: GuitarTonePreset) -> TimeInterval {
        switch preset {
        case .acoustic:      return AudioConstants.acousticDelayTime
        case .electricClean: return AudioConstants.electricCleanDelayTime
        case .electricDirty: return AudioConstants.electricDirtyDelayTime
        }
    }

    private func noteLength(for preset: GuitarTonePreset) -> TimeInterval {
        switch preset {
        case .acoustic:      return AudioConstants.acousticNoteLength
        case .electricClean: return AudioConstants.electricCleanNoteLength
        case .electricDirty: return AudioConstants.electricDirtyNoteLength
        }
    }

    private func effectiveVelocity(for preset: GuitarTonePreset, requested: Float) -> Float {
        switch preset {
        case .electricDirty: return min(requested, AudioConstants.electricDirtyVelocityCap)
        default: return requested
        }
    }

    private func effectiveSustainMultiplier(for preset: GuitarTonePreset, requested: Double) -> Double {
        let clamped = max(requested, AudioConstants.sustainMultiplierMin)
        switch preset {
        case .electricClean, .electricDirty: return min(clamped, AudioConstants.sustainMultiplierMax)
        case .acoustic: return clamped
        }
    }

    private func reverbPreset(for preset: GuitarTonePreset) -> AVAudioUnitReverbPreset {
        switch preset {
        case .acoustic: return .mediumRoom
        case .electricClean: return .mediumHall
        case .electricDirty: return .largeHall
        }
    }

    private func fallbackSoundBankURLs() -> [URL] {
        [URL(fileURLWithPath: "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls")]
    }

    // MARK: - MIDI internals

    private func loadMIDISamplers() {
        guard let sf2URL = Bundle.main.url(forResource: "GeneralUser GS v1.472", withExtension: "sf2") else {
            #if DEBUG
            print("[SharedAudioEngine] SoundFont not found")
            #endif
            return
        }

        loadMIDIInstrument(sampler: keysSampler, program: 0, bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB), bankLSB: 0, url: sf2URL)
        loadMIDIInstrument(sampler: bassSampler, program: 33, bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB), bankLSB: 0, url: sf2URL)
        loadMIDIInstrument(sampler: drumsSampler, program: 0, bankMSB: UInt8(kAUSampler_DefaultPercussionBankMSB), bankLSB: 0, url: sf2URL)
    }

    private func loadMIDIInstrument(sampler: AVAudioUnitSampler, program: UInt8, bankMSB: UInt8, bankLSB: UInt8, url: URL) {
        do {
            try sampler.loadSoundBankInstrument(at: url, program: program, bankMSB: bankMSB, bankLSB: bankLSB)
        } catch {
            #if DEBUG
            print("[SharedAudioEngine] Failed to load instrument program \(program): \(error)")
            #endif
        }
    }

    private func routeTracksToSamplers() {
        for (index, track) in sequencer.tracks.enumerated() {
            track.isMuted = false
            switch index {
            case 0: track.destinationAudioUnit = bassSampler
            case 1: track.destinationAudioUnit = drumsSampler
            default: track.destinationAudioUnit = bassSampler
            }
        }
    }

    private func configureTrackLooping() {
        for track in sequencer.tracks {
            track.loopRange = AVBeatRange(start: 0, length: loopLengthInBeats)
            track.numberOfLoops = -1
            track.isLoopingEnabled = true
        }
    }

    private func applyBassTranspose() {
        sendAllNotesOff(to: bassSampler)
        bassSampler.globalTuning = Float(bassTransposeSemitones * 100)
    }

    private func sendAllNotesOff(to sampler: AVAudioUnitSampler) {
        for channel: UInt8 in 0...15 {
            sampler.sendController(123, withValue: 0, onChannel: channel)
        }
    }

    private func startEngineIfNeeded() {
        guard !engine.isRunning else { return }
        do {
            try engine.start()
        } catch {
            #if DEBUG
            print("[SharedAudioEngine] Engine start failed - \(error)")
            #endif
        }
    }

    deinit {
        sequencer.stop()
        engine.stop()
    }
}
