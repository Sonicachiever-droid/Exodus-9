import SwiftUI

struct AudioPageView: View {
    @Bindable var audioSettings: AudioSettings
    let availableBackingTracks: [BackingTrack]
    let onDone: () -> Void

    private var hasBackingTracks: Bool {
        !availableBackingTracks.isEmpty
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Guitar Sound") {
                    Picker("Preset", selection: $audioSettings.guitarTonePreset) {
                        ForEach(GuitarTonePreset.allCases) { preset in
                            Text(preset.rawValue).tag(preset)
                        }
                    }
                }


                Section("Tempo") {
                    Picker("Increase Per Round", selection: $audioSettings.tempoIncreasePerRound) {
                        ForEach(TempoIncreasePerRound.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                }

            }
            #if os(iOS)
            .navigationTitle("Audio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        onDone()
                    }
                }
            }
            #else
            .navigationTitle("Audio")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        onDone()
                    }
                }
            }
            #endif
        }
    }
}
