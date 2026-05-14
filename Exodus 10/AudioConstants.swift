import Foundation

// MARK: - Audio Constants

enum AudioConstants {

    // MARK: - Sampler Volumes
    static let keysVolume: Float   = 0.65
    static let bassVolume: Float   = 0.85
    static let drumsVolume: Float  = 0.70
    static let masterVolume: Float = 0.72

    // MARK: - Guitar Note Velocity
    static let defaultNoteVelocity: Float      = 0.92
    static let electricDirtyVelocityCap: Float = 0.62

    // MARK: - Note Lengths by Preset (seconds)
    static let acousticNoteLength: TimeInterval      = 1.35
    static let electricCleanNoteLength: TimeInterval = 1.6
    static let electricDirtyNoteLength: TimeInterval = 1.2

    // MARK: - Delay Times by Preset (seconds)
    static let acousticDelayTime: TimeInterval      = 0.12
    static let electricCleanDelayTime: TimeInterval = 0.16
    static let electricDirtyDelayTime: TimeInterval = 0.18

    // MARK: - Reverb / Delay Feedback Levels
    static let feedbackOff: Float    = 0
    static let feedbackLow: Float    = 14
    static let feedbackMedium: Float = 24
    static let feedbackHigh: Float   = 34
    static let electricDirtyFeedbackBoost: Float = 6

    // MARK: - Sustain Multiplier Clamp Bounds
    static let sustainMultiplierMin: Double = 0.1
    static let sustainMultiplierMax: Double = 1.5

    // MARK: - Sequencer
    static let loopLengthInBeats: TimeInterval = 16
}
