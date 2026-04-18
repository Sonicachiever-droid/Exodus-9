import AVFoundation
import Combine

final class SimpleMIDIEngine: ObservableObject {

    private let engine = AVAudioEngine()
    private let sequencer: AVAudioSequencer

    // Multiple samplers for different instruments
    private let keysSampler = AVAudioUnitSampler()
    private let bassSampler = AVAudioUnitSampler()
    private let drumsSampler = AVAudioUnitSampler()

    @Published var isPlaying: Bool = false
    @Published var currentTrackTitle: String = ""

    private(set) var currentURL: URL?
    var activeURL: URL? { currentURL }
    private var isLooping: Bool = true
    private var loopTimer: Timer?
    private let loopLengthInBeats: TimeInterval = 16
    private var bassTransposeSemitones: Int = 0
    private var pausedPositionInBeats: TimeInterval?

    init() {
        self.sequencer = AVAudioSequencer(audioEngine: engine)
        setupAudioEngine()
        setupAudioSession()
    }

    private func setupAudioEngine() {
        // Attach all samplers to engine
        engine.attach(keysSampler)
        engine.attach(bassSampler)
        engine.attach(drumsSampler)

        // Connect samplers to mixer
        engine.connect(keysSampler, to: engine.mainMixerNode, format: nil)
        engine.connect(bassSampler, to: engine.mainMixerNode, format: nil)
        engine.connect(drumsSampler, to: engine.mainMixerNode, format: nil)

        // Set volumes - boost bass
        keysSampler.volume = 0.8
        bassSampler.volume = 1.2  // Louder bass
        drumsSampler.volume = 0.9

        // Load SF2 into each sampler with appropriate instruments
        loadSamplers()

        // Start engine
        do {
            try engine.start()
            print("[SimpleMIDIEngine] AVAudioEngine started")
        } catch {
            print("[SimpleMIDIEngine] Failed to start engine: \(error)")
        }
    }

    private func loadSamplers() {
        guard let sf2URL = Bundle.main.url(forResource: "GeneralUser GS v1.472", withExtension: "sf2") else {
            print("[SimpleMIDIEngine] ⚠️ SoundFont not found")
            return
        }

        // Keys: Piano (program 0)
        loadInstrument(sampler: keysSampler, program: 0, bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB), bankLSB: 0, url: sf2URL)

        // Bass: Electric Bass (program 33)
        loadInstrument(sampler: bassSampler, program: 33, bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB), bankLSB: 0, url: sf2URL)

        // Drums: Standard Kit (program 0, percussion bank)
        loadInstrument(sampler: drumsSampler, program: 0, bankMSB: UInt8(kAUSampler_DefaultPercussionBankMSB), bankLSB: 0, url: sf2URL)
    }

    private func loadInstrument(sampler: AVAudioUnitSampler, program: UInt8, bankMSB: UInt8, bankLSB: UInt8, url: URL) {
        do {
            try sampler.loadSoundBankInstrument(at: url, program: program, bankMSB: bankMSB, bankLSB: bankLSB)
            print("[SimpleMIDIEngine] Loaded instrument program \(program) into sampler")
        } catch {
            print("[SimpleMIDIEngine] Failed to load instrument: \(error)")
        }
    }

    private func setupAudioSession() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            print("[SimpleMIDIEngine] Audio session configured")
        } catch {
            print("[SimpleMIDIEngine] Audio session error: \(error)")
        }
        #endif
    }

    func play(url: URL, title: String = "", loop: Bool = true) {
        stop()

        currentURL = url
        currentTrackTitle = title.isEmpty ? url.lastPathComponent : title
        isLooping = loop
        isStopped = false
        pausedPositionInBeats = nil

        do {
            // Load MIDI file
            try sequencer.load(from: url)

            // Route tracks to appropriate samplers
            routeTracksToSamplers()
            applyBassTranspose()

            // Use track-level looping (reliable, tiny gap acceptable)
            if loop {
                configureTrackLooping()
            }

            sequencer.prepareToPlay()
            try sequencer.start()

            DispatchQueue.main.async {
                self.isPlaying = true
            }

            print("[SimpleMIDIEngine] Playing: \(currentTrackTitle) (looping: \(loop))")

        } catch {
            print("[SimpleMIDIEngine] Failed to play: \(error)")
        }
    }

    private func startLoopTimer() {
        // Calculate loop duration in seconds at current tempo
        let beatsPerSecond = (sequencer.rate * 120.0) / 60.0
        let loopDuration = loopLengthInBeats / Double(beatsPerSecond)

        // Use a timer that fires slightly before the end to ensure gapless loop
        loopTimer?.invalidate()
        loopTimer = Timer.scheduledTimer(withTimeInterval: loopDuration - 0.005, repeats: true) { [weak self] _ in
            guard let self = self, self.isLooping, !self.isStopped else { return }

            // Seamlessly restart
            self.sequencer.currentPositionInBeats = 0
            if !self.sequencer.isPlaying {
                try? self.sequencer.start()
            }
        }
    }

    private func routeTracksToSamplers() {
        for (index, track) in sequencer.tracks.enumerated() {
            track.isMuted = false

            // Debug: Print track info
            print("[SimpleMIDIEngine] Track \(index): length = \(track.lengthInBeats) beats")

            // Route based on track index (2-track MIDI format)
            switch index {
            case 0:
                track.destinationAudioUnit = bassSampler
                print("[SimpleMIDIEngine] Track \(index) -> bassSampler")
            case 1:
                track.destinationAudioUnit = drumsSampler
                print("[SimpleMIDIEngine] Track \(index) -> drumsSampler")
            default:
                track.destinationAudioUnit = bassSampler
                print("[SimpleMIDIEngine] Track \(index) -> bassSampler (default)")
            }
        }
        print("[SimpleMIDIEngine] Routed \(sequencer.tracks.count) tracks to samplers")
    }

    private func configureTrackLooping() {
        for track in sequencer.tracks {
            track.loopRange = AVBeatRange(start: 0, length: loopLengthInBeats)
            track.numberOfLoops = -1  // Infinite loops
            track.isLoopingEnabled = true
        }
        print("[SimpleMIDIEngine] Track-level looping configured (\(loopLengthInBeats) beats)")
    }

    func setBassTransposeSemitones(_ semitones: Int) {
        bassTransposeSemitones = semitones
        applyBassTranspose()
    }

    private func applyBassTranspose() {
        // Stop all bass notes first to prevent "swoop" effect when changing pitch
        sendAllNotesOff(to: bassSampler)
        bassSampler.globalTuning = Float(bassTransposeSemitones * 100)
    }

    private func sendAllNotesOff(to sampler: AVAudioUnitSampler) {
        // Send All Notes Off (CC 123) on all channels
        for channel: UInt8 in 0...15 {
            sampler.sendController(123, withValue: 0, onChannel: channel)
        }
    }

    func muteTrack1() {
        if sequencer.tracks.count > 1 {
            sequencer.tracks[1].isMuted = true
            print("[SimpleMIDIEngine] Track 1 muted")
        }
    }

    func muteTrack2() {
        if sequencer.tracks.count > 2 {
            sequencer.tracks[2].isMuted = true
            print("[SimpleMIDIEngine] Track 2 muted")
        }
    }

    func muteTrack3() {
        if sequencer.tracks.count > 3 {
            sequencer.tracks[3].isMuted = true
            print("[SimpleMIDIEngine] Track 3 muted")
        }
    }

    func muteTrack0() {
        if sequencer.tracks.count > 0 {
            sequencer.tracks[0].isMuted = true
            print("[SimpleMIDIEngine] Track 0 muted")
        }
    }

    func unmuteAllTracks() {
        for track in sequencer.tracks {
            track.isMuted = false
        }
        print("[SimpleMIDIEngine] All tracks unmuted")
    }

    private var isStopped: Bool = false

    func pause() {
        guard sequencer.isPlaying else { return }
        pausedPositionInBeats = max(sequencer.currentPositionInBeats, 0)
        sequencer.stop()

        DispatchQueue.main.async {
            self.isPlaying = false
        }
        print("[SimpleMIDIEngine] Paused at beat \(pausedPositionInBeats ?? 0)")
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
            print("[SimpleMIDIEngine] Resumed at beat \(sequencer.currentPositionInBeats)")
        } catch {
            print("[SimpleMIDIEngine] Failed to resume: \(error)")
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
        print("[SimpleMIDIEngine] Stopped")
    }

    func setTempo(bpm: Double) {
        sequencer.rate = Float(bpm / 120.0)
        print("[SimpleMIDIEngine] Tempo changed to \(bpm) BPM")
    }

    func currentBeatPosition() -> Double {
        max(sequencer.currentPositionInBeats, 0)
    }

    func setLooping(_ looping: Bool) {
        isLooping = looping
        // Update track looping for all tracks
        for track in sequencer.tracks {
            track.numberOfLoops = looping ? -1 : 1
            track.isLoopingEnabled = looping
        }
        print("[SimpleMIDIEngine] Looping set to: \(looping)")
    }

    deinit {
        sequencer.stop()
        engine.stop()
    }
}
