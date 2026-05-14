import SwiftUI

// MARK: - Lesson Style (replaces all playLessonStyle string comparisons)

enum LessonStyle: String, CaseIterable {
    case chord
    case sequential
}

// MARK: - Game Constants (replaces all magic numbers)

enum GameConstants {
    static let maxRevealCount: Int = 6
    static let revealGateBeats: Int = 7        // beats elapsed before autoplay unlocks
    static let roundShiftDelayBeats: Double = 2.0
    static let autoPlayInterval: TimeInterval = 0.38
    static let minBPM: Int = 60
    static let stringCount: Int = 6
    // Left column: strings top→bottom = 4, 5, 6
    static let leftColumnStrings: [Int] = [4, 5, 6]
    // Right column: strings top→bottom = 3, 2, 1
    static let rightColumnStrings: [Int] = [3, 2, 1]
}

// MARK: - Animation Durations

enum AnimationDurations {
    /// Eased transition for launch/round-start screen wipe
    static let launchTransition: TimeInterval = 0.4725
    /// Quick beat-flash for the startup sequence armed state
    static let beatFlash: TimeInterval = 0.08
    /// Short delay before a reset takes effect
    static let resetDelay: TimeInterval = 0.3
    /// Flash period for the "armed" banner in the startup sequence
    static let armedFlashPeriod: TimeInterval = 1.0
}

// MARK: - Audio Constants

enum AudioVelocity {
    /// Standard full-strength note velocity
    static let full: Float = 0.98
    /// Softer velocity used when force-playing prompted notes
    static let soft: Float = 0.82
}

// MARK: - UI Dimensions

enum UIMetrics {
    /// Font size for the startup sequence label
    static let startupFontSize: CGFloat = 29.6
    /// Maximum fraction of row height for the banner
    static let bannerHeightFraction: CGFloat = 0.66
    /// Maximum banner height in points
    static let bannerMaxHeight: CGFloat = 50
    /// Minimum banner height in points
    static let bannerMinHeight: CGFloat = 40
    /// Font scale applied to MiniTVFrame banners
    static let bannerFontScale: CGFloat = 0.82
}

// MARK: - Core Enums (unchanged from Exodus-5)

enum GameplayMenuOption: String, CaseIterable, Identifiable {
    case home
    case learn
    case guide
    case audio

    var id: String { rawValue }
    var title: String {
        switch self {
        case .home: return "HOME"
        case .learn: return "PLAY"
        case .guide: return "GUIDE"
        case .audio: return "AUDIO"
        }
    }
}

enum RefretMode: String, CaseIterable, Identifiable {
    case freestyle
    case beat
    case chord
    case mixed
    case oneHand
    case twoHand

    var id: String { rawValue }
}

enum GameplayModeVariant {
    case freestyle
    case beat
    case chord
}

enum AnswerSide {
    case left
    case right
}

enum LayoutMode {
    case beginner
    case maestro
}

enum BeginnerRoundZeroIntroDisplayPhase {
    case inactive
    case centeredRoundZeroChordMode
    case roundZeroHeader
    case roundZeroScaleTitle
    case noteReveal
}

enum ThumbGlowState: CaseIterable {
    case neutral
    case orange
    case green
    case red
}

enum Orientation: String, CaseIterable {
    case portrait
    case landscape
}

// MARK: - Console Skin System

enum ConsoleSkin: String, CaseIterable {
    case classic
    case tweed

    var rawValue: String {
        switch self {
        case .classic: return "classic"
        case .tweed: return "tweed"
        }
    }

    var price: Int {
        switch self {
        case .classic: return 0
        case .tweed: return 500
        }
    }

    var isPurchased: Bool {
        switch self {
        case .classic: return true
        case .tweed: return UserDefaults.standard.bool(forKey: "exodus10.purchased.tweed")
        }
    }

    static func purchaseTweed() {
        UserDefaults.standard.set(true, forKey: "exodus10.purchased.tweed")
    }
}

// MARK: - Core Types

struct HighlightWindowShape: InsettableShape {
    var cornerRadius: CGFloat
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let radius = max(0, cornerRadius - insetAmount)
        return RoundedRectangle(cornerRadius: radius, style: .continuous).path(in: insetRect)
    }

    func inset(by amount: CGFloat) -> some InsettableShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }
}

// MARK: - Layout Constants

enum FretMath {
    static func fretPositionRatios(totalFrets: Int, scaleLength: Double) -> [CGFloat] {
        let safeFrets = max(totalFrets, 1)
        let safeScale = max(scaleLength, 0.001)
        return (0...safeFrets).map { fret in
            let distance = safeScale - (safeScale / pow(2.0, Double(fret) / 12.0))
            return CGFloat(distance / safeScale)
        }
    }
}

enum GuitarStringLayout {
    static let totalStrings: Int = 6
    static let highestStringNumber: Int = 6
    private static let stratNutWidthInches: CGFloat = 1.650
    private static let stratStringSpanInches: CGFloat = 1.362

    static func stringCenters(containerWidth: CGFloat, neckWidth: CGFloat) -> [CGFloat] {
        guard containerWidth > 0, neckWidth > 0 else {
            return Array(repeating: containerWidth / 2, count: totalStrings)
        }

        let nutWidth = neckWidth * 0.99
        let overallPadding = (containerWidth - nutWidth) / 2
        let widthPerInch = nutWidth / stratNutWidthInches
        let interStringSpacing = (stratStringSpanInches / CGFloat(totalStrings - 1)) * widthPerInch
        let edgeMargin = ((stratNutWidthInches - stratStringSpanInches) / 2) * widthPerInch

        return (0..<totalStrings).map { index in
            overallPadding + edgeMargin + CGFloat(index) * interStringSpacing
        }
    }
}

// MARK: - Helper Functions

func baselineNutTargetY(highlightTopGridLineY: CGFloat, gridRowHeight: CGFloat) -> CGFloat {
    highlightTopGridLineY + (gridRowHeight * 2)
}

func resolvedNeckTopY(
    currentFretStart: Int,
    nutTargetY: CGFloat,
    highlightCenterY: CGFloat,
    activeMidpoint: CGFloat
) -> CGFloat {
    if currentFretStart == 0 {
        return nutTargetY
    }
    return highlightCenterY - activeMidpoint
}

// MARK: - Beginner Scale / Reward Types (moved from BeginnerGameplayView, Step 5)

struct BeginnerStageTemplate {
    let root: String
    let titleSuffix: String
    let intervals: [Int]
    let bassSemitoneTarget: Int
    let endsCycle: Bool
}

struct BeginnerScaleStage {
    let title: String
    let notes: [String]
    let bassSemitoneTarget: Int
    let endsCycle: Bool
}

struct BeginnerRewardPolicyKey: Hashable {
    let stageIndex: Int
    let fret: Int?
}

struct BeginnerRewardPolicy {
    let isRewardEnabled: Bool
    let delayBeats: Double
    let sustainMultiplier: Double
    let preferredStrings: [Int]?
}
