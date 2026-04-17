import Foundation

// MARK: - Guitar Note Helpers (extracted from BeginnerGameplayView — now shared)

let chromaticSharps: [String] = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
let chromaticFlats:  [String] = ["C","Db","D","Eb","E","F","Gb","G","Ab","A","Bb","B"]

let openNoteByString: [Int: String] = [
    6: "E",
    5: "A",
    4: "D",
    3: "G",
    2: "B",
    1: "E"
]

func guitarNoteName(forString string: Int, fret: Int, useFlats: Bool) -> String {
    guard let openNote = openNoteByString[string],
          let openIndex = chromaticSharps.firstIndex(of: openNote) else {
        return "?"
    }
    let noteIndex = (openIndex + fret) % chromaticSharps.count
    let scale = useFlats ? chromaticFlats : chromaticSharps
    return scale[noteIndex]
}
