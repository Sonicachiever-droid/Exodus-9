import SwiftUI
import AVFoundation
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock: UIInterfaceOrientationMask = .portrait

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}

@main
struct Exodus_10App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var selectedMenuOption: GameplayMenuOption?
    @State private var layoutMode: LayoutMode? = nil
    @AppStorage("exodus10.progress.walletPoints") private var walletPoints: Int = 0
    @AppStorage("exodus10.progress.balancePoints") private var balancePoints: Int = 0
    @AppStorage("exodus10.setup.startingFret") private var startingFret: Int = 0
    @AppStorage("exodus10.setup.repetitions") private var repetitions: Int = 5
    @AppStorage("exodus10.setup.infiniteRepetitions") private var infiniteRepetitions: Bool = false
    @AppStorage("exodus10.setup.direction") private var directionRawValue: String = LessonDirection.ascending.rawValue
    @AppStorage("exodus10.setup.enableHighFrets") private var enableHighFrets: Bool = false
    @AppStorage("exodus10.setup.lessonStyle") private var lessonStyleRawValue: String = "chord"
    @AppStorage("exodus10.setup.selectedMode") private var selectedModeRawValue: String = "beginner"
    @AppStorage("exodus10.setup.progression") private var progressionRawValue: String = "highToLow"
    @AppStorage("exodus10.setup.orientation") private var orientationRawValue: String = Orientation.portrait.rawValue
    @AppStorage("exodus10.setup.consoleSkin") private var consoleSkinRawValue: String = ConsoleSkin.classic.rawValue
    @AppStorage("exodus10.setup.premiumUnlocked") private var premiumUnlocked: Bool = false

    private var orientation: Orientation {
        Orientation(rawValue: orientationRawValue) ?? .portrait
    }

    private var consoleSkin: ConsoleSkin {
        get { ConsoleSkin(rawValue: consoleSkinRawValue) ?? .classic }
        set { consoleSkinRawValue = newValue.rawValue }
    }

    init() {
        let savedMode = UserDefaults.standard.string(forKey: "exodus10.setup.selectedMode") ?? "beginner"
        let savedOrientation = UserDefaults.standard.string(forKey: "exodus10.setup.orientation") ?? Orientation.portrait.rawValue
        // Always portrait on launch — welcome screen is always shown first
        AppDelegate.orientationLock = .portrait
        _ = savedMode
        _ = savedOrientation
        // FIX A5: Single audio session configuration — no per-engine conflicts
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[Exodus 10] Audio session configuration failed: \(error)")
        }
        #endif

        if LessonDirection(rawValue: directionRawValue) == nil {
            directionRawValue = LessonDirection.ascending.rawValue
        }
        // Clamp persisted values to what the user has actually purchased
        let landscapePurchased = UserDefaults.standard.bool(forKey: "exodus10.purchased.landscape")
        if !landscapePurchased {
            UserDefaults.standard.set(Orientation.portrait.rawValue, forKey: "exodus10.setup.orientation")
        }
        let highFretsPurchased = UserDefaults.standard.bool(forKey: "exodus10.purchased.highFrets")
        if !highFretsPurchased {
            UserDefaults.standard.set(false, forKey: "exodus10.setup.enableHighFrets")
        }
        // Always show welcome screen on cold launch
        layoutMode = nil
    }

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
                            playInfiniteRepetitions: $infiniteRepetitions,
                            playDirectionRawValue: $directionRawValue,
                            playEnableHighFrets: $enableHighFrets,
                            playLessonStyle: $lessonStyleRawValue,
                            playProgression: $progressionRawValue,
                            walletDollars: $walletPoints,
                            balanceDollars: $balancePoints,
                            consoleSkin: consoleSkin
                        )
                    case .maestro:
                        MaestroGameplayView(
                            onMenuSelection: { option in
                                selectedMenuOption = option
                            },
                            playStartingFret: $startingFret,
                            playRepetitions: $repetitions,
                            playInfiniteRepetitions: $infiniteRepetitions,
                            playDirectionRawValue: $directionRawValue,
                            playEnableHighFrets: $enableHighFrets,
                            playLessonStyle: $lessonStyleRawValue,
                            playProgression: $progressionRawValue,
                            walletDollars: $walletPoints,
                            balanceDollars: $balancePoints,
                            orientation: orientation,
                            consoleSkin: consoleSkin
                        )
                    }
                } else {
                    WelcomeScreenView(
                        onSelectBeginner: { layoutMode = .beginner },
                        onSelectMaestro: { layoutMode = .maestro }
                    )
                }
            }
            .onChange(of: layoutMode) { _, newMode in
                if newMode == .beginner {
                    selectedModeRawValue = "beginner"
                    // Beginner has no landscape — always lock portrait
                    AppDelegate.orientationLock = .portrait
                    #if os(iOS)
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        windowScene.requestGeometryUpdate(UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)) { _ in }
                    }
                    #endif
                } else if newMode == .maestro {
                    selectedModeRawValue = "maestro"
                    // Always lock portrait when switching to maestro (user must explicitly choose landscape)
                    orientationRawValue = Orientation.portrait.rawValue
                    AppDelegate.orientationLock = .portrait
                    #if os(iOS)
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        windowScene.requestGeometryUpdate(UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)) { _ in }
                    }
                    #endif
                }
                SharedAudioEngine.shared.stopAll()
            }
            .sheet(item: $selectedMenuOption) { option in
                Exodus10MenuSheet(
                    option: option,
                    walletPoints: $walletPoints,
                    balancePoints: $balancePoints,
                    startingFret: $startingFret,
                    repetitions: $repetitions,
                    infiniteRepetitions: $infiniteRepetitions,
                    directionRawValue: $directionRawValue,
                    enableHighFrets: $enableHighFrets,
                    lessonStyleRawValue: $lessonStyleRawValue,
                    progressionRawValue: $progressionRawValue,
                    layoutMode: $layoutMode,
                    orientationRawValue: $orientationRawValue,
                    consoleSkinRawValue: $consoleSkinRawValue
                )
            }
            .onChange(of: orientationRawValue) { _, newValue in
                let landscapePurchased = UserDefaults.standard.bool(forKey: "exodus10.purchased.landscape")
                // Only allow landscape if in maestro mode AND purchase has been made
                guard layoutMode == .maestro, landscapePurchased else {
                    orientationRawValue = Orientation.portrait.rawValue
                    AppDelegate.orientationLock = .portrait
                    return
                }
                if newValue == Orientation.landscape.rawValue {
                    AppDelegate.orientationLock = .landscape
                } else {
                    AppDelegate.orientationLock = .portrait
                }
                #if os(iOS)
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    let geometryPreferences: UIWindowScene.GeometryPreferences.iOS
                    if newValue == Orientation.landscape.rawValue {
                        geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .landscape)
                    } else {
                        geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)
                    }
                    windowScene.requestGeometryUpdate(geometryPreferences) { error in
                        print("[Exodus 10] Orientation change error: \(error)")
                    }
                }
                #endif
            }
        }
    }
}


private struct MenuRow: View {
    let label: String
    let value: String
    let gold: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(gold)
        }
    }
}

private struct MenuTextRow: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 16, weight: .medium, design: .monospaced))
            .foregroundColor(.white.opacity(0.85))
            .lineSpacing(5)
    }
}

private struct Exodus10MenuSheet: View {
    let option: GameplayMenuOption
    @Binding var walletPoints: Int
    @Binding var balancePoints: Int
    @Binding var startingFret: Int
    @Binding var repetitions: Int
    @Binding var infiniteRepetitions: Bool
    @Binding var directionRawValue: String
    @Binding var enableHighFrets: Bool
    @Binding var lessonStyleRawValue: String
    @Binding var progressionRawValue: String
    @Binding var layoutMode: LayoutMode?
    @Binding var orientationRawValue: String
    @Binding var consoleSkinRawValue: String
    @AppStorage("exodus10.purchased.tweed") private var tweedPurchased: Bool = false
    @AppStorage("exodus10.purchased.highFrets") private var highFretsPurchased: Bool = false
    @AppStorage("exodus10.purchased.landscape") private var landscapePurchased: Bool = false
    @AppStorage("exodus10.runtime.directionLockActive") private var directionLockActive: Bool = false
    @Environment(\.dismiss) private var dismiss
    @State private var isButtonPressed: Bool = false

    private var consoleSkin: ConsoleSkin {
        get { ConsoleSkin(rawValue: consoleSkinRawValue) ?? .classic }
        set { consoleSkinRawValue = newValue.rawValue }
    }

    private var repetitionDisplay: String {
        infiniteRepetitions ? "∞" : "\(repetitions)"
    }

    private let gold = Color.goldBorderMid
    private let goldDim = Color.goldBorderMid.opacity(0.55)

    var body: some View {
        NavigationStack {
            ZStack {
                FullScreenElephantBackground()
                    .ignoresSafeArea()
                Color.black.opacity(0.55)
                    .ignoresSafeArea()
                GoldPipingBorder(bottomInset: 0)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        switch option {
                        case .home:
                            MenuSection(title: "PROGRESS", gold: gold) {
                                MenuRow(label: "Wallet", value: "$\(walletPoints)", gold: gold)
                                MenuRow(label: "Balance", value: "$\(balancePoints)", gold: gold)
                            }
                            MenuSection(title: "UNLOCKS", gold: gold) {
                                // High Frets row
                                if highFretsPurchased {
                                    Toggle("Enable High Frets (12+)", isOn: $enableHighFrets)
                                        .foregroundColor(.white)
                                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                                        .tint(gold)
                                        .accessibilityLabel(A11y.Settings.highFretsToggle)
                                        .accessibilityHint(A11y.Settings.highFretsHint)
                                        .onChange(of: enableHighFrets) { _, isEnabled in
                                            if !isEnabled {
                                                startingFret = min(startingFret, 12)
                                            }
                                        }
                                } else {
                                    Button(action: {
                                        if balancePoints >= 500 {
                                            balancePoints -= 500
                                            highFretsPurchased = true
                                        }
                                    }) {
                                        HStack {
                                            Text("Enable High Frets (12+)")
                                                .font(.system(size: 16, weight: .medium, design: .monospaced))
                                                .foregroundColor(balancePoints >= 500 ? .white.opacity(0.7) : .white.opacity(0.3))
                                            Spacer()
                                            Text("$500")
                                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                                .foregroundColor(balancePoints >= 500 ? gold : .red)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(balancePoints < 500)
                                    .accessibilityLabel(A11y.Settings.buyHighFrets)
                                    .accessibilityHint(A11y.Settings.buyHighFretsHint(canAfford: balancePoints >= 500))
                                }
                                // Landscape row
                                if landscapePurchased {
                                    GoldPickerRow(
                                        label: "Layout",
                                        options: [
                                            (label: "Portrait", value: Orientation.portrait.rawValue),
                                            (label: "Landscape", value: Orientation.landscape.rawValue)
                                        ],
                                        selection: $orientationRawValue
                                    )
                                } else {
                                    Button(action: {
                                        if balancePoints >= 500 {
                                            balancePoints -= 500
                                            landscapePurchased = true
                                        }
                                    }) {
                                        HStack {
                                            Text("Landscape Mode")
                                                .font(.system(size: 16, weight: .medium, design: .monospaced))
                                                .foregroundColor(balancePoints >= 500 ? .white.opacity(0.7) : .white.opacity(0.3))
                                            Spacer()
                                            Text("$500")
                                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                                .foregroundColor(balancePoints >= 500 ? gold : .red)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(balancePoints < 500)
                                    .accessibilityLabel(A11y.Settings.buyLandscape)
                                    .accessibilityHint(A11y.Settings.buyLandscapeHint(canAfford: balancePoints >= 500))
                                }
                            }
                            MenuSection(title: "SKINS", gold: gold) {
                                // Classic row
                                Button(action: { consoleSkinRawValue = ConsoleSkin.classic.rawValue }) {
                                    HStack {
                                        Text("Classic")
                                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                                            .foregroundColor(.white.opacity(0.7))
                                        Spacer()
                                        if consoleSkin == .classic {
                                            Text("ACTIVE")
                                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                                .foregroundColor(Color.green)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(A11y.Settings.skinClassic)
                                .accessibilityHint(A11y.Settings.skinClassicHint(isActive: consoleSkin == .classic))
                                .accessibilityAddTraits(consoleSkin == .classic ? [.isSelected] : [])
                                // Tweed row
                                Button(action: {
                                    if tweedPurchased {
                                        consoleSkinRawValue = ConsoleSkin.tweed.rawValue
                                    } else if balancePoints >= 500 {
                                        balancePoints -= 500
                                        ConsoleSkin.purchaseTweed()
                                        tweedPurchased = true
                                    }
                                }) {
                                    HStack {
                                        Text("Tweed")
                                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                                            .foregroundColor(tweedPurchased ? .white.opacity(0.7) : (balancePoints >= 500 ? gold : .white.opacity(0.3)))
                                        Spacer()
                                        if consoleSkin == .tweed {
                                            Text("ACTIVE")
                                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                                .foregroundColor(Color.green)
                                        } else if tweedPurchased {
                                            Text("owned")
                                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                                .foregroundColor(.white.opacity(0.4))
                                        } else {
                                            Text("$500")
                                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                                .foregroundColor(balancePoints >= 500 ? gold : .red)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .disabled(!tweedPurchased && balancePoints < 500)
                                .accessibilityLabel(A11y.Settings.skinTweed)
                                .accessibilityHint(A11y.Settings.skinTweedHint(purchased: tweedPurchased, canAfford: balancePoints >= 500, isActive: consoleSkin == .tweed))
                                .accessibilityAddTraits(consoleSkin == .tweed ? [.isSelected] : [])
                            }
                            MenuSection(title: "HELP", gold: gold) {
                                Button(action: {
                                    dismiss()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        layoutMode = nil
                                    }
                                }) {
                                    HStack {
                                        Text("Learn the Game")
                                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                                            .foregroundColor(.white.opacity(0.7))
                                        Spacer()
                                        Image(systemName: "book.fill")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(gold)
                                    }
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Learn the game guide")
                                .accessibilityHint("Return to the welcome screen to learn how to play")
                            }

                        case .learn:
                            MenuSection(title: "LESSON SETUP", gold: gold) {
                                if layoutMode == .beginner {
                                    GoldPickerRow(
                                        label: "Style",
                                        options: [
                                            (label: "Sequential", value: "sequential"),
                                            (label: "Chord", value: "chord")
                                        ],
                                        selection: $lessonStyleRawValue
                                    )
                                }

                                Stepper("Repetitions: \(repetitionDisplay)", value: $repetitions, in: 1...8)
                                    .disabled(infiniteRepetitions)
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                                    .tint(gold)
                                    .accessibilityLabel(A11y.Settings.repetitionsStepper)
                                    .accessibilityValue(A11y.Settings.repetitionsValue(repetitions))

                                Toggle("Infinite Repetitions", isOn: $infiniteRepetitions)
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                                    .tint(gold)
                                    .accessibilityLabel(A11y.Settings.infiniteRepsToggle)
                                    .accessibilityHint(A11y.Settings.infiniteRepsHint)

                                Stepper("Starting Fret: \(startingFret)", value: $startingFret, in: 0...(highFretsPurchased && enableHighFrets ? 19 : 12))
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                                    .tint(gold)
                                    .accessibilityLabel(A11y.Settings.startingFretStepper)
                                    .accessibilityValue(A11y.Settings.startingFretValue(startingFret))
                                    .onChange(of: startingFret) { _, newValue in
                                        if newValue == 0 {
                                            directionRawValue = LessonDirection.ascending.rawValue
                                        } else if newValue >= (highFretsPurchased && enableHighFrets ? 19 : 12) {
                                            directionRawValue = LessonDirection.descending.rawValue
                                        }
                                    }

                                let upperBound = highFretsPurchased && enableHighFrets ? 19 : 12
                                let descendingLocked = startingFret == 0
                                let ascendingLocked = startingFret >= upperBound
                                GoldPickerRow(
                                    label: "Direction",
                                    options: [
                                        (label: "Ascending", value: LessonDirection.ascending.rawValue),
                                        (label: "Descending", value: LessonDirection.descending.rawValue)
                                    ],
                                    selection: Binding(
                                        get: { directionRawValue },
                                        set: { newValue in
                                            let isDescending = newValue == LessonDirection.descending.rawValue
                                            if isDescending && descendingLocked { return }
                                            if !isDescending && ascendingLocked { return }
                                            directionRawValue = newValue
                                        }
                                    )
                                )

                                let progressionLocked = layoutMode == .beginner && lessonStyleRawValue == "chord"
                                GoldPickerRow(
                                    label: "Progression",
                                    options: [
                                        (label: "High → Low", value: "highToLow"),
                                        (label: "Low → High", value: "lowToHigh")
                                    ],
                                    selection: $progressionRawValue,
                                    disabled: progressionLocked
                                )

                            }

                            MenuSection(title: "CONSOLE", gold: gold) {
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                        isButtonPressed = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                        if layoutMode == .beginner {
                                            layoutMode = .maestro
                                        } else {
                                            layoutMode = .beginner
                                        }
                                        dismiss()
                                    }
                                } label: {
                                    Text(layoutMode == .beginner ? "SWITCH TO MAESTRO" : "SWITCH TO BEGINNER")
                                        .font(.system(size: 16, weight: .black, design: .monospaced))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color.black.opacity(0.65))
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .strokeBorder(
                                                    LinearGradient(
                                                        colors: [.goldBorderMid, .goldBorderDark, .goldBorderLight],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 1.5
                                                )
                                        )
                                }
                                .scaleEffect(isButtonPressed ? 1.04 : 1.0)
                                .animation(.spring(response: 0.25, dampingFraction: 0.4), value: isButtonPressed)
                                .accessibilityLabel(layoutMode == .beginner ? "Switch to Maestro mode" : "Switch to Beginner mode")
                                .accessibilityHint(layoutMode == .beginner ? "Switches to the advanced Maestro console" : "Switches to the Beginner console")
                            }

                        case .guide:
                            MenuSection(title: "THE GAME", gold: gold) {
                                MenuTextRow("ReFret drills you on note names across the guitar neck. Each round covers one fret — from open strings (round 0) through fret 19. Complete all strings on a fret to advance.")
                            }
                            MenuSection(title: "CONSOLES", gold: gold) {
                                MenuTextRow("BEGINNER — Six buttons appear, one per string, each showing a note name. Tap the correct note for the highlighted string. Notes are shown before each round.")
                                MenuTextRow("MAESTRO — No labels. Recall the correct note name from memory and tap it.")
                            }
                            MenuSection(title: "LESSON STYLES", gold: gold) {
                                MenuTextRow("SEQUENTIAL — Notes are revealed string by string before each round. Answer each in order.")
                                MenuTextRow("CHORD — All string positions are active at once. Answer the highlighted string.")
                            }
                            MenuSection(title: "TOOLBAR BUTTONS", gold: gold) {
                                MenuTextRow("FRETBOARD — Shows all note names at the current fret position for reference.")
                                MenuTextRow("AUTO — Plays correct answers automatically. Use to listen and learn. Tap again to stop.")
                                MenuTextRow("RESET — Returns to round 0 (open strings) while preserving current settings.")
                            }
                            MenuSection(title: "SCORING", gold: gold) {
                                MenuTextRow("Each correct answer earns $1 (Beginner) or $2 (Maestro). Wrong answers score nothing. Balance carries forward between sessions.")
                            }

                        case .audio:
                            MenuSection(title: "AUDIO", gold: gold) {
                                MenuTextRow("Use the AUDIO tab to select guitar tone preset and tempo settings.")
                            }
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .onAppear { directionLockActive = false }
            .navigationTitle(option.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black.opacity(0.85), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(gold)
                        .accessibilityLabel(A11y.Settings.doneButton)
                        .accessibilityHint(A11y.Settings.doneHint)
                }
            }
        }
    }
}
