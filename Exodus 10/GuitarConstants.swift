import Foundation

// MARK: - Guitar Constants

enum GuitarConstants {

    // MARK: - Strat Geometry (inches)
    static let stratNutWidth: Double = 1.650
    static let stratStringSpan: Double = 1.362

    // MARK: - Open String MIDI Notes (standard tuning)
    // String 6 = E2, 5 = A2, 4 = D3, 3 = G3, 2 = B3, 1 = E4
    static let openMIDINotesByString: [Int: Int] = [
        6: 40, 5: 45, 4: 50, 3: 55, 2: 59, 1: 64,
    ]

    // MARK: - MIDI Bounds
    static let midiNoteMin: Int = 24
    static let midiNoteMax: Int = 88

    // MARK: - Guitar Tone Preset SF2 Program Numbers
    static let programAcoustic: UInt8     = 24
    static let programElectricClean: UInt8 = 27
    static let programElectricDirty: UInt8 = 30

    // MARK: - Fretboard Layout Ratios
    static let nutWidthRatio: CGFloat     = 0.99   // neck width multiplier
    static let stringGapMultiplier: CGFloat = 0.12  // gap between strings
    static let nutHeightOffset: CGFloat   = 0.15   // nut visual height offset
    static let gridRowHeightRatio: CGFloat = 0.18  // status area grid row height
}
