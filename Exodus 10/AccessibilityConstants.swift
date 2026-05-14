import SwiftUI

// MARK: - Accessibility Constants
// Centralised VoiceOver labels and hints for every interactive element
// in Deuteronomy 1. Add `.accessibilityLabel(A11y.*)` at the call site.

enum A11y {

    // MARK: - Welcome Screen
    enum Welcome {
        static let beginnerButton       = "Beginner mode"
        static let beginnerHint         = "Opens the beginner guitar training lesson"
        static let maestroButton        = "Maestro mode"
        static let maestroHint          = "Opens the advanced Maestro training lesson"
        static let overviewButton       = "App overview"
        static let overviewHint         = "Shows an overview of how the app works"
    }

    // MARK: - Control Plate (GameplayControlViews)
    enum ControlPlate {
        static let autoplay             = "Autoplay"
        static let autoplayHintOff      = "Starts automatic playback of guitar notes"
        static let autoplayHintOn       = "Stops automatic playback"
        static let fretboard            = "Fretboard guide"
        static let fretboardHint        = "Opens the fretboard reference chart"
        static let menuOpen             = "Open menu"
        static let menuOpenHint         = "Shows navigation options: Home, Audio, Guide, Learn"
        static let menuClose            = "Close menu"
        static let menuCloseHint        = "Hides the navigation menu"
        static func menuOption(_ title: String) -> String { title }
        static func menuOptionHint(_ title: String) -> String { "Opens the \(title) panel" }
    }

    // MARK: - Transport Controls (START / PAUSE / RESUME / RESET)
    enum Transport {
        static let start                = "Start"
        static let startHint            = "Starts the current lesson round"
        static let pause                = "Pause"
        static let pauseHint            = "Pauses the current lesson round"
        static let resume               = "Resume"
        static let resumeHint           = "Resumes the paused lesson round"
        static let reset                = "Reset"
        static let resetHint            = "Resets the current lesson round to the beginning"
    }

    // MARK: - Beginner Mode Answer Buttons
    enum Beginner {
        static func consoleButton(note: String, stringNumber: Int) -> String {
            "String \(stringNumber), \(note)"
        }
        static func consoleButtonHint(note: String) -> String {
            "Select \(note) as your answer for this string"
        }
        static let leftThumb            = "Left answer"
        static let leftThumbHint        = "Submit the left-side answer"
        static let rightThumb           = "Right answer"
        static let rightThumbHint       = "Submit the right-side answer"
    }

    // MARK: - Maestro Mode Answer Buttons
    enum Maestro {
        static let leftThumb            = "Left answer"
        static let leftThumbHint        = "Submit the left-side answer"
        static let rightThumb           = "Right answer"
        static let rightThumbHint       = "Submit the right-side answer"
    }

    // MARK: - Settings Menu (Exodus_10App)
    enum Settings {
        // Toggles
        static let highFretsToggle      = "Enable high frets"
        static let highFretsHint        = "Allows lessons starting above fret 12"
        static let infiniteRepsToggle   = "Infinite repetitions"
        static let infiniteRepsHint     = "When on, the lesson repeats without a fixed count"

        // Steppers
        static let repetitionsStepper   = "Repetitions"
        static func repetitionsValue(_ n: Int) -> String { "\(n) repetitions" }
        static let startingFretStepper  = "Starting fret"
        static func startingFretValue(_ n: Int) -> String { "Fret \(n)" }

        // Purchase / unlock buttons
        static let buyHighFrets         = "Unlock high frets"
        static func buyHighFretsHint(canAfford: Bool) -> String {
            canAfford ? "Purchase high frets for 500 points" : "Not enough balance — need 500 points"
        }
        static let buyLandscape         = "Unlock landscape mode"
        static func buyLandscapeHint(canAfford: Bool) -> String {
            canAfford ? "Purchase landscape layout for 500 points" : "Not enough balance — need 500 points"
        }

        // Skin buttons
        static let skinClassic          = "Classic skin"
        static func skinClassicHint(isActive: Bool) -> String {
            isActive ? "Currently active" : "Switch to the classic gold console skin"
        }
        static let skinTweed            = "Tweed skin"
        static func skinTweedHint(purchased: Bool, canAfford: Bool, isActive: Bool) -> String {
            if isActive   { return "Currently active" }
            if purchased  { return "Switch to the tweed console skin" }
            if canAfford  { return "Purchase tweed skin for 500 points" }
            return "Not enough balance — need 500 points"
        }

        // Orientation picker
        static let layoutPicker         = "Layout orientation"
        static let layoutHint           = "Choose between portrait and landscape layout"

        // Done button
        static let doneButton           = "Done"
        static let doneHint             = "Closes this settings panel"
    }
}
