import Foundation
import SwiftUI

enum GuitarTonePreset: String, CaseIterable, Identifiable {
    case acoustic = "Acoustic"
    case electricClean = "Electric Clean"
    case electricDirty = "Electric Dirty"

    var id: String { rawValue }
}

enum AudioEffectLevel: String, CaseIterable, Identifiable {
    case off = "Off"
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var id: String { rawValue }
}

enum BackingArrangementPreset: String, CaseIterable, Identifiable {
    case epDrumsPad = "EP + Drums + Pad"
    case keysDrumsStrings = "Keys + Drums + Strings"
    case epDrumsOnly = "EP + Drums Only"
    case padDrumsOnly = "Pad + Drums Only"

    var id: String { rawValue }
}

enum TempoIncreasePerRound: Int, CaseIterable, Identifiable {
    case off = 0
    case plus1 = 1
    case plus2 = 2
    case plus3 = 3
    case plus4 = 4
    case plus5 = 5

    var id: Int { rawValue }

    var title: String {
        rawValue == 0 ? "Off" : "+\(rawValue) BPM"
    }
}

@Observable
final class AudioSettings {
    var guitarTonePreset: GuitarTonePreset = .acoustic
    var reverbLevel: AudioEffectLevel = .off
    var delayLevel: AudioEffectLevel = .off
    var selectedBackingArrangement: BackingArrangementPreset = .epDrumsPad
    var selectedBackingTrackID: String? = nil
    var tempoIncreasePerRound: TempoIncreasePerRound = .off

    func selectInitialBackingTrackIfNeeded(from tracks: [BackingTrack]) {
        if let selectedBackingTrackID,
           tracks.contains(where: { $0.id == selectedBackingTrackID }) {
            return
        }
        selectedBackingTrackID = preferredBackingTrack(from: tracks)?.id
    }

    private func preferredBackingTrack(from tracks: [BackingTrack]) -> BackingTrack? {
        let beginnerLoops = tracks.filter { $0.resourceName.lowercased().hasPrefix("beginner_loop_") }
        if let preferredBeginnerLoop = beginnerLoops.max(by: { $0.resourceName.localizedStandardCompare($1.resourceName) == .orderedAscending }) {
            return preferredBeginnerLoop
        }
        return tracks.first
    }
}
