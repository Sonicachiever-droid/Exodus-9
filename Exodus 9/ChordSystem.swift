import Foundation
import Combine

// MARK: - Chord Data Model
enum ChordType: String, CaseIterable, Identifiable {
    // Triad & Power Chord Subsets
    case gMajorTriad = "G major triad (G–B–D)"
    case eMinorTriad = "E minor triad (E–G–B)"
    case d5Power = "D5 power (D–A)"
    case a5Power = "A5 power (A–E)"

    // Four-Note Subsets (missing one note)
    case e7sus4 = "E7sus4 (E–A–B–D) // missing G"
    case em7approx = "Em7 approx (E–A–D–G) // missing B"
    case emAdd4 = "Em(add4/add11) (E–A–G–B) // missing D"
    case em7 = "Em7 (E–D–G–B) // missing A"
    case a7sus4 = "A7sus4 / A11(no3) (A–D–G–B) // missing E"
    case a7sus4approx = "A7sus4 approx (A–D–G–E) // missing B"

    // Five-Note & Extended Subsets
    case gadd9 = "Gadd9 / Gadd2 (G–A–B–D)"
    case g6 = "G6 (G–B–D–E)"
    case g69 = "G6/9 (G–A–B–D–E)"
    case em7full = "Em7 (E–G–B–D)"
    case emAdd9 = "Em(add9/add2) (E–G–A–B)"
    case emAdd11 = "Em(add4/add11) (E–A–G–B)"
    case em11 = "Em11 / Em7add11 (E–G–A–B–D)"
    case dsus4 = "Dsus4 / D(add4) (D–G–A)"
    case asus2 = "Asus2 / A(add9) (A–B–E)"
    case quartalE = "Quartal on E (E–A–D–G)"
    case quartalA = "Quartal on A (A–D–G–B–E)"
    case quartalD = "Quartal on D (D–G–B–E–A)"
    case cluster = "Ambiguous cluster / full set (E–A–D–G–B)"

    var id: String { rawValue }

    // Extract note pattern from raw value
    var notePattern: [String] {
        let pattern = rawValue.components(separatedBy: " (").last?
            .components(separatedBy: ")").first?
            .components(separatedBy: "–") ?? []
        return pattern.map { $0.trimmingCharacters(in: .whitespaces) }
    }

    // Check if chord contains specific note
    func containsNote(_ note: String) -> Bool {
        return notePattern.contains(note)
    }

    // Get compatibility score with a set of notes (0.0 to 1.0)
    func compatibilityScore(with notes: Set<String>) -> Double {
        let chordNotes = Set(notePattern)
        let intersection = chordNotes.intersection(notes)
        return Double(intersection.count) / Double(chordNotes.count)
    }

    // Check if chord is fully compatible (all notes in set)
    func isFullyCompatible(with notes: Set<String>) -> Bool {
        return Set(notePattern).isSubset(of: notes)
    }

    // Get missing notes from a note set
    func missingNotes(from notes: Set<String>) -> [String] {
        return Set(notePattern).subtracting(notes).sorted()
    }
}

// MARK: - Fret Note Calculator
struct FretNoteCalculator {
    // Standard guitar tuning (low to high): E A D G B E
    static let openStrings: [String] = ["E", "A", "D", "G", "B", "E"]

    // Chromatic scale starting from E (for semitone shifting)
    static let chromaticFromE = [
        "E", "F", "F#", "G", "G#", "A", "A#", "B", "C", "C#", "D", "D#"
    ]

    // Alternative with flats for enharmonic spelling
    static let chromaticFromEFlats = [
        "E", "F", "Gb", "G", "Ab", "A", "Bb", "B", "C", "Db", "D", "Eb"
    ]

    // Get the note at a given string and fret
    static func noteAt(string: Int, fret: Int, useFlats: Bool = false) -> String {
        guard string >= 0 && string < openStrings.count else { return "?" }

        let openNote = openStrings[string]
        let chromatic = useFlats ? chromaticFromEFlats : chromaticFromE

        guard let openIndex = chromatic.firstIndex(of: openNote) else { return "?" }
        let newIndex = (openIndex + fret) % 12
        return chromatic[newIndex]
    }

    // Get the unique set of notes when playing all strings at the same fret
    static func notesAtFret(_ fret: Int, useFlats: Bool = false) -> Set<String> {
        return Set((0..<openStrings.count).map { noteAt(string: $0, fret: fret, useFlats: useFlats) })
    }

    // Get human-readable description for a fret
    static func descriptionForFret(_ fret: Int, useFlats: Bool = false) -> String {
        let notes = notesAtFret(fret, useFlats: useFlats).sorted { a, b in
            let chromatic = useFlats ? chromaticFromEFlats : chromaticFromE
            let indexA = chromatic.firstIndex(of: a) ?? 0
            let indexB = chromatic.firstIndex(of: b) ?? 0
            return indexA < indexB
        }

        let joined = notes.joined(separator: ", ")
        let pentatonicType: String
        switch fret % 12 {
        case 0: pentatonicType = "E minor / G major pentatonic"
        case 5: pentatonicType = "A minor / C major pentatonic"
        case 7: pentatonicType = "B minor / D major pentatonic"
        case 10: pentatonicType = "D minor / F major pentatonic"
        default: pentatonicType = "\(joined) pentatonic set"
        }

        return "Fret \(fret): \(joined) (\(pentatonicType))"
    }

    // Transpose a note pattern by a given number of semitones
    static func transposeNotes(_ notes: [String], by semitones: Int, useFlats: Bool = false) -> [String] {
        let chromatic = useFlats ? chromaticFromEFlats : chromaticFromE
        return notes.compactMap { note in
            guard let index = chromatic.firstIndex(of: note) else { return nil }
            let newIndex = (index + semitones) % 12
            return chromatic[newIndex]
        }
    }
}

// MARK: - Chord Generator
class ChordGenerator: ObservableObject {
    @Published var currentChord: ChordType?
    @Published var currentFretNotes: Set<String> = []
    @Published var availableChords: [ChordType] = []

    // Generate chords for a specific fret position
    func generateChords(for fret: Int, useFlats: Bool = false) {
        currentFretNotes = FretNoteCalculator.notesAtFret(fret, useFlats: useFlats)

        // Filter chords by compatibility
        let compatibleChords = ChordType.allCases.compactMap { chord -> (ChordType, Double)? in
            let score = chord.compatibilityScore(with: currentFretNotes)
            return score > 0.3 ? (chord, score) : nil // Minimum compatibility threshold
        }.sorted { $0.1 > $1.1 } // Sort by compatibility score

        availableChords = compatibleChords.map { $0.0 }

        // Select a chord (weighted random based on compatibility)
        if let selected = selectWeightedChord(from: compatibleChords) {
            currentChord = selected
        }
    }

    // Select chord with weighted probability based on compatibility score
    private func selectWeightedChord(from chords: [(ChordType, Double)]) -> ChordType? {
        guard !chords.isEmpty else { return nil }

        let totalScore = chords.reduce(0) { $0 + $1.1 }
        let random = Double.random(in: 0..<totalScore)

        var accumulated = 0.0
        for (chord, score) in chords {
            accumulated += score
            if random <= accumulated {
                return chord
            }
        }

        return chords.last?.0
    }

    // Get transposed chord notes for current fret
    func getTransposedChordNotes(for fret: Int) -> [String] {
        guard let chord = currentChord else { return [] }
        return FretNoteCalculator.transposeNotes(chord.notePattern, by: fret)
    }

    // Check if a note fits with the current chord
    func noteFitsChord(_ note: String, at fret: Int) -> Bool {
        guard currentChord != nil else { return false }
        let transposedNotes = getTransposedChordNotes(for: fret)
        return transposedNotes.contains(note)
    }

    // Get educational explanation for current chord
    func getChordExplanation() -> String {
        guard let chord = currentChord else { return "" }

        let missingNotes = chord.missingNotes(from: currentFretNotes)
        let compatibility = chord.compatibilityScore(with: currentFretNotes)

        var explanation = "\(chord.rawValue)\n"
        explanation += "Compatibility: \(Int(compatibility * 100))%\n"

        if !missingNotes.isEmpty {
            explanation += "Missing notes: \(missingNotes.joined(separator: ", "))\n"
            explanation += "These notes may sound slightly tense if emphasized."
        } else {
            explanation += "Fully compatible - all notes fit perfectly!"
        }

        return explanation
    }
}
