import SwiftUI

// MARK: - Lesson Style (replaces all playLessonStyle string comparisons)

enum LessonStyle: String, CaseIterable {
    case chord
    case sequential
    case random
}

// MARK: - Game Phase (finite state machine — replaces 15+ bools)

enum GamePhase: Equatable {
    case screensaver
    case phaseAnnouncement
    case revealing
    case playing
    case phaseComplete
}

// MARK: - Game Constants (replaces all magic numbers)

enum GameConstants {
    static let maxRevealCount: Int = 6
    static let revealGateBeats: Int = 7        // beats elapsed before autoplay unlocks
    static let roundShiftDelayBeats: Double = 2.0
    static let autoPlayInterval: TimeInterval = 0.38
    static let phaseAnnouncementBeats: Double = 8.0
    static let phaseCompletionAutoAdvanceBeats: Double = 4.0
    static let minBPM: Int = 60
    static let minPhase: Int = 1
    static let maxPhase: Int = 4
    static let stringCount: Int = 6
    // Left column: strings top→bottom = 4, 5, 6
    static let leftColumnStrings: [Int] = [4, 5, 6]
    // Right column: strings top→bottom = 3, 2, 1
    static let rightColumnStrings: [Int] = [3, 2, 1]
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

enum BeginnerCoursePhase {
    case round1Ascending
    case round1Celebration
    case round2Arming
    case round2Descending
    case round2Celebration
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
