import CoreGraphics

// MARK: - UI Constants

enum UIConstants {

    // MARK: - Console Frame Corner Radii
    static let consoleFrameRadius: CGFloat      = 26   // outer console frame
    static let consoleInnerBorderRadius: CGFloat = 22   // inner bevel ring
    static let consoleContentRadius: CGFloat    = 18   // screen content area
    static let consoleInnerFrameRadius: CGFloat = 14   // innermost frame layer

    // MARK: - Control Plate
    static let controlPlateRadius: CGFloat      = 20   // plate shell corner radius
    static let controlPlateButtonRadius: CGFloat = 7   // button corner radius
    static let controlPlateButtonHeight: CGFloat = 34  // button fixed height
    static let controlPlatePaddingH: CGFloat    = 14   // horizontal padding
    static let controlPlatePaddingV: CGFloat    = 11   // vertical padding

    // MARK: - Transport Buttons
    static let transportButtonHeight: CGFloat   = 27
    static let transportButtonMinWidth: CGFloat = 46

    // MARK: - Answer / Note Choice Box
    static let answerBoxRadius: CGFloat         = 8

    // MARK: - Power Indicator
    static let powerIndicatorDiameter: CGFloat  = 28
    static let powerIndicatorDotDiameter: CGFloat = 14

    // MARK: - Indicator Dots
    static let indicatorDotSmall: CGFloat       = 8
    static let indicatorDotMedium: CGFloat      = 12

    // MARK: - MiniTV Bezel Insets
    static let miniTVBezelInsetW: CGFloat       = 24   // bezel width added around screen
    static let miniTVBezelInsetH: CGFloat       = 18   // bezel height added around screen

    // MARK: - Console Frame Padding / Insets
    static let consoleFramePadding: CGFloat     = 3
    static let consoleContentPadding: CGFloat   = 12

    // MARK: - Fret Indicator Spacing
    static let fretIndicatorSpacing: CGFloat    = 28

    // MARK: - Progress Bar
    static let progressBarRadius: CGFloat       = 1.5
}
