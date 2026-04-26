import Foundation
import Combine

// MARK: - Unified Note Sequence Generator Protocol

protocol NoteSequenceGenerator: AnyObject {
    var currentNoteSequence: [String] { get }
    var noteStringMap: [Int] { get }
    var sequenceProgressIndex: Int { get }
    var expectedString: Int? { get }
    func isSequenceComplete() -> Bool
    func isValidAnswer(note: String, string: Int) -> Bool
    func advanceSequence()
    func resetForNewFret()
    func generateNoteSequence(for fret: Int, useFlats: Bool, lowToHigh: Bool)
}

// MARK: - Random Note Generator

final class RandomNoteGenerator: ObservableObject, NoteSequenceGenerator {
    private(set) var currentNoteSequence: [String] = []
    private(set) var noteStringMap: [Int] = []
    private(set) var sequenceProgressIndex: Int = 0
    private var usedStringLocations: Set<String> = []

    private let openStringPairs: [(note: String, string: Int)] = [
        ("E", 6), ("A", 5), ("D", 4), ("G", 3), ("B", 2), ("E", 1)
    ]

    func generateNoteSequence(for fret: Int, useFlats: Bool, lowToHigh: Bool = true) {
        let sharps = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
        let flats  = ["C","Db","D","Eb","E","F","Gb","G","Ab","A","Bb","B"]
        let chromatic = useFlats ? flats : sharps
        var pairs: [(note: String, string: Int)] = []
        for entry in openStringPairs {
            if let i = chromatic.firstIndex(of: entry.note) {
                pairs.append((chromatic[(i + fret) % 12], entry.string))
            }
        }
        pairs.shuffle()
        currentNoteSequence = pairs.map { $0.note }
        noteStringMap = pairs.map { $0.string }
        usedStringLocations.removeAll()
        sequenceProgressIndex = 0
    }

    var expectedString: Int? {
        guard sequenceProgressIndex < noteStringMap.count else { return nil }
        return noteStringMap[sequenceProgressIndex]
    }

    func isSequenceComplete() -> Bool {
        sequenceProgressIndex >= currentNoteSequence.count
    }

    func isValidAnswer(note: String, string: Int) -> Bool {
        guard sequenceProgressIndex < currentNoteSequence.count else { return false }
        guard note == currentNoteSequence[sequenceProgressIndex] else { return false }
        return !usedStringLocations.contains("\(note)-\(string)")
    }

    func advanceSequence() {
        guard sequenceProgressIndex < currentNoteSequence.count else { return }
        let note = currentNoteSequence[sequenceProgressIndex]
        let string = noteStringMap[sequenceProgressIndex]
        usedStringLocations.insert("\(note)-\(string)")
        sequenceProgressIndex += 1
    }

    func resetForNewFret() {
        currentNoteSequence.removeAll()
        noteStringMap.removeAll()
        usedStringLocations.removeAll()
        sequenceProgressIndex = 0
    }
}

// MARK: - Sequential Note Generator

final class SequentialNoteGenerator: ObservableObject, NoteSequenceGenerator {
    private(set) var currentNoteSequence: [String] = []
    private(set) var noteStringMap: [Int] = []
    private(set) var sequenceProgressIndex: Int = 0
    private var usedStringLocations: Set<String> = []

    private let openStringPairs: [(note: String, string: Int)] = [
        ("E", 6), ("A", 5), ("D", 4), ("G", 3), ("B", 2), ("E", 1)
    ]

    func generateNoteSequence(for fret: Int, useFlats: Bool, lowToHigh: Bool = true) {
        let sharps = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
        let flats  = ["C","Db","D","Eb","E","F","Gb","G","Ab","A","Bb","B"]
        let chromatic = useFlats ? flats : sharps
        var pairs: [(note: String, string: Int)] = []
        for entry in openStringPairs {
            if let i = chromatic.firstIndex(of: entry.note) {
                pairs.append((chromatic[(i + fret) % 12], entry.string))
            }
        }
// Removed shuffle - sequential mode should not randomize notes
        // lowToHigh = strings 6→5→4→3→2→1 (ascending pitch)
        // highToLow = strings 1→2→3→4→5→6 (descending pitch)
        let ordered = lowToHigh ? pairs : pairs.reversed()
        currentNoteSequence = ordered.map { $0.note }
        noteStringMap = ordered.map { $0.string }
        usedStringLocations.removeAll()
        sequenceProgressIndex = 0
    }

    var expectedString: Int? {
        guard sequenceProgressIndex < noteStringMap.count else { return nil }
        return noteStringMap[sequenceProgressIndex]
    }

    func isSequenceComplete() -> Bool {
        sequenceProgressIndex >= currentNoteSequence.count
    }

    func isValidAnswer(note: String, string: Int) -> Bool {
        guard sequenceProgressIndex < currentNoteSequence.count else { return false }
        guard note == currentNoteSequence[sequenceProgressIndex] else { return false }
        return !usedStringLocations.contains("\(note)-\(string)")
    }

    func advanceSequence() {
        guard sequenceProgressIndex < currentNoteSequence.count else { return }
        let note = currentNoteSequence[sequenceProgressIndex]
        let string = noteStringMap[sequenceProgressIndex]
        usedStringLocations.insert("\(note)-\(string)")
        sequenceProgressIndex += 1
    }

    func resetForNewFret() {
        currentNoteSequence.removeAll()
        noteStringMap.removeAll()
        usedStringLocations.removeAll()
        sequenceProgressIndex = 0
    }
}
