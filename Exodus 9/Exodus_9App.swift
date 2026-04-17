//
//  Exodus_8App.swift
//  Exodus 8
//
//  Created by Thomas Kane on 4/11/26.
//

import SwiftUI
import SwiftData

@main
struct Exodus_9App: App {
    @State private var selectedMenuOption: GameplayMenuOption?
    @State private var layoutMode: LayoutMode? = nil
    @AppStorage("numbers3.progress.walletPoints") private var walletPoints: Int = 0
    @AppStorage("numbers3.progress.balancePoints") private var balancePoints: Int = 0
    @AppStorage("numbers3.setup.startingFret") private var startingFret: Int = 0
    @AppStorage("numbers3.setup.repetitions") private var repetitions: Int = 5
    @AppStorage("numbers3.setup.direction") private var directionRawValue: String = LessonDirection.ascending.rawValue
    @AppStorage("numbers3.setup.enableHighFrets") private var enableHighFrets: Bool = false
    @AppStorage("numbers3.setup.lessonStyle") private var lessonStyleRawValue: String = "chord"
    @AppStorage("numbers3.setup.selectedMode") private var selectedModeRawValue: String = "beginner"

    init() {
        if LessonDirection(rawValue: directionRawValue) == nil {
            directionRawValue = LessonDirection.ascending.rawValue
        }
        if selectedModeRawValue == "beginner" {
            layoutMode = .beginner
        } else if selectedModeRawValue == "maestro" {
            layoutMode = .maestro
        }
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if let mode = layoutMode {
                    switch mode {
                    case .beginner:
                        BeginnerGameplayView(
                            onMenuSelection: { option in
                                selectedMenuOption = option
                            },
                            playStartingFret: $startingFret,
                            playRepetitions: $repetitions,
                            playDirectionRawValue: $directionRawValue,
                            playEnableHighFrets: $enableHighFrets,
                            playLessonStyle: $lessonStyleRawValue,
                            walletDollars: $walletPoints,
                            balanceDollars: $balancePoints
                        )
                    case .maestro:
                        MaestroGameplayView(
                            onMenuSelection: { option in
                                selectedMenuOption = option
                            },
                            playStartingFret: $startingFret,
                            playRepetitions: $repetitions,
                            playDirectionRawValue: $directionRawValue,
                            playEnableHighFrets: $enableHighFrets,
                            playLessonStyle: $lessonStyleRawValue,
                            walletDollars: $walletPoints,
                            balanceDollars: $balancePoints
                        )
                    }
                } else {
                    ZStack {
                        Color.black.opacity(0.6)
                            .ignoresSafeArea()
                        VStack(spacing: 20) {
                            Text("Choose Console")
                                .font(.title2).bold()
                                .foregroundColor(.white)
                            VStack(spacing: 12) {
                                Button {
                                    layoutMode = .beginner
                                } label: {
                                    Text("Beginner Console")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue.opacity(0.9))
                                        .cornerRadius(12)
                                }
                                Button {
                                    layoutMode = .maestro
                                } label: {
                                    Text("Maestro Console")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.gray.opacity(0.9))
                                        .cornerRadius(12)
                                }
                            }
                            .frame(maxWidth: 320)
                        }
                        .padding(24)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.4), radius: 16, x: 0, y: 6)
                    }
                }
            }
            .onChange(of: layoutMode) { _, newMode in
                if newMode == .beginner {
                    selectedModeRawValue = "beginner"
                } else if newMode == .maestro {
                    selectedModeRawValue = "maestro"
                }
            }
            .sheet(item: $selectedMenuOption) { option in
                Exodus9MenuSheet(
                    option: option,
                    walletPoints: $walletPoints,
                    balancePoints: $balancePoints,
                    startingFret: $startingFret,
                    repetitions: $repetitions,
                    directionRawValue: $directionRawValue,
                    enableHighFrets: $enableHighFrets,
                    lessonStyleRawValue: $lessonStyleRawValue,
                    layoutMode: $layoutMode
                )
            }
        }
        .modelContainer(sharedModelContainer)
    }
}

private struct Exodus9MenuSheet: View {
    let option: GameplayMenuOption
    @Binding var walletPoints: Int
    @Binding var balancePoints: Int
    @Binding var startingFret: Int
    @Binding var repetitions: Int
    @Binding var directionRawValue: String
    @Binding var enableHighFrets: Bool
    @Binding var lessonStyleRawValue: String
    @Binding var layoutMode: LayoutMode?
    @AppStorage("numbers3.runtime.directionLockActive") private var directionLockActive: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                switch option {
                case .home:
                    Section("Progress") {
                        LabeledContent("Wallet", value: "\(walletPoints)")
                        LabeledContent("Balance", value: "\(balancePoints)")
                    }
                case .learn:
                    Section("Lesson Setup") {
                        Picker("Style", selection: $lessonStyleRawValue) {
                            Text("Random").tag("random")
                            Text("Sequential").tag("sequential")
                            Text("Chord").tag("chord")
                        }

                        Stepper("Repetitions: \(repetitions)", value: $repetitions, in: 1...8)

                        Stepper("Starting Fret: \(startingFret)", value: $startingFret, in: 0...(enableHighFrets ? 19 : 12))

                        Picker("Direction", selection: $directionRawValue) {
                            Text("Ascending").tag(LessonDirection.ascending.rawValue)
                            Text("Descending").tag(LessonDirection.descending.rawValue)
                        }
                        .disabled(directionLockActive)

                        Toggle("Enable High Frets (12+)", isOn: $enableHighFrets)
                    }
                    .onChange(of: enableHighFrets) { _, isEnabled in
                        if !isEnabled {
                            startingFret = min(startingFret, 12)
                        }
                    }

                    Section {
                        Button {
                            if layoutMode == .beginner {
                                layoutMode = .maestro
                            } else {
                                layoutMode = .beginner
                            }
                            dismiss()
                        } label: {
                            HStack {
                                Spacer()
                                Text(layoutMode == .beginner ? "Switch to Maestro Mode" : "Switch to Beginner Mode")
                                    .font(.headline)
                                Spacer()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                case .phases:
                    Section("Controls") {
                        Text("HINT: Shows the correct note for the current question.")
                        Text("FRETBOARD: Toggles a visual guide showing all notes at current fret position.")
                        Text("MENU: Opens additional options (HOME, PLAY, GUIDE, AUDIO).")
                        Text("AUTO: Toggles autoplay mode (automatically plays correct notes).")
                        Text("LEFT/RIGHT buttons: Submit your answer for the left or right thumb position.")
                    }
                case .audio:
                    Section("Audio") {
                        Text("Use the in-game AUDIO page for backing track and instrument mix settings.")
                    }
                }
            }
            .navigationTitle(option.title)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
