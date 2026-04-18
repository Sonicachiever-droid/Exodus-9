import SwiftUI

// MARK: - Beginner Button Panel View
// Renders the 3x2 grid of thumb buttons + note labels + beat light.
// Left column top→bottom: strings 4, 5, 6
// Right column top→bottom: strings 3, 2, 1

struct BeginnerButtonPanelView: View {
    let engine: BeginnerGameEngine
    let containerWidth: CGFloat
    let containerHeight: CGFloat
    let buttonCenterY: CGFloat
    let transportCenterY: CGFloat
    let lowerScreenWidth: CGFloat
    let lowerScreenHeight: CGFloat
    let isArmedAndVisible: Bool
    let noteName: (Int, Int, Bool) -> String  // (string, fret, useFlats) -> note

    private let leftStrings  = GameConstants.leftColumnStrings   // [4, 5, 6]
    private let rightStrings = GameConstants.rightColumnStrings  // [3, 2, 1]

    private var buttonDiameter: CGFloat {
        min(max(containerWidth * 0.18, 66), 84) * 0.85
    }
    private var buttonSpacing: CGFloat { buttonDiameter * 1.62 }
    private var rowYs: [CGFloat] {
        [buttonCenterY - buttonSpacing, buttonCenterY, buttonCenterY + buttonSpacing]
    }
    private var leftButtonX: CGFloat  { containerWidth * 0.2335 }
    private var rightButtonX: CGFloat { containerWidth * 0.7665 }
    private var screenWidth: CGFloat  { lowerScreenWidth * 0.54 }
    private var screenHeight: CGFloat { lowerScreenHeight * 0.76 }
    private var screenYOffset: CGFloat { -buttonDiameter * 0.13 }
    private var leftScreenX: CGFloat  { leftButtonX + buttonDiameter * 0.88 }
    private var rightScreenX: CGFloat { rightButtonX - buttonDiameter * 0.88 }
    private var blueLightY: CGFloat {
        let top = rowYs[0]
        let panel = transportCenterY + 6
        return top + (panel - top) * 0.62
    }

    var body: some View {
        ZStack {
            // Left column
            ForEach(0..<3, id: \.self) { idx in
                let str  = leftStrings[idx]
                let note = noteName(str, engine.currentFret, engine.useFlats)
                let btnIdx = idx  // string 4→0, 5→1, 6→2

                MiniTVFrame(text: note, width: screenWidth, height: screenHeight, fontScale: 1.0)
                    .position(x: leftScreenX, y: rowYs[idx] + screenYOffset)

                Button {
                    engine.handleButtonPress(note: note, string: str, buttonIndex: btnIdx)
                } label: {
                    ThumbButtonView(
                        diameter: buttonDiameter,
                        label: "",
                        state: buttonState(for: btnIdx)
                    )
                }
                .buttonStyle(.plain)
                .position(x: leftButtonX, y: rowYs[idx])
            }

            // Right column
            ForEach(0..<3, id: \.self) { idx in
                let str  = rightStrings[idx]
                let note = noteName(str, engine.currentFret, engine.useFlats)
                let btnIdx = idx + 3  // string 3→3, 2→4, 1→5

                MiniTVFrame(text: note, width: screenWidth, height: screenHeight, fontScale: 1.0)
                    .position(x: rightScreenX, y: rowYs[idx] + screenYOffset)

                Button {
                    engine.handleButtonPress(note: note, string: str, buttonIndex: btnIdx)
                } label: {
                    ThumbButtonView(
                        diameter: buttonDiameter,
                        label: "",
                        state: buttonState(for: btnIdx)
                    )
                }
                .buttonStyle(.plain)
                .position(x: rightButtonX, y: rowYs[idx])
            }

            // Beat light
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.62, green: 0.86, blue: 1.0),
                            Color(red: 0.09, green: 0.45, blue: 1.0)
                        ],
                        center: .center,
                        startRadius: 0.5,
                        endRadius: 10
                    )
                )
                .frame(width: 18, height: 18)
                .shadow(color: Color(red: 0.28, green: 0.7, blue: 1.0).opacity(0.95), radius: 12)
                .shadow(color: Color.white.opacity(0.45), radius: 5)
                .overlay(Circle().stroke(Color.white.opacity(0.75), lineWidth: 1))
                .position(x: leftButtonX, y: blueLightY)
                .opacity(engine.state.beatLightFlashOn ? 1 : 0)
                .animation(.easeOut(duration: 0.08), value: engine.state.beatLightFlashOn)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func buttonState(for idx: Int) -> ThumbGlowState {
        if let pressed = engine.pressedButtonIndex, pressed == idx {
            return engine.pressedButtonCorrect ? .green : .red
        }
        if isArmedAndVisible { return .green }
        return .neutral
    }
}
