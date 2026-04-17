import SwiftUI

// MARK: - Beginner Console View
// Displays revealed notes, phase messages, or phase completion text.

struct BeginnerConsoleView: View {
    let engine: BeginnerGameEngine
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack {
            if let text = displayText, !text.isEmpty {
                Text(text)
                    .font(.system(
                        size: min(width * 0.19, 52),
                        weight: .black,
                        design: .monospaced
                    ))
                    .foregroundStyle(Color.green.opacity(0.98))
                    .minimumScaleFactor(0.3)
                    .lineLimit(3)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding(.horizontal, 10)
                    .padding(.top, 24)
                    .padding(.bottom, 8)
                    .allowsHitTesting(false)
            }
        }
    }

    private var displayText: String? {
        // Phase completed message
        if engine.state.phaseCompletedMessagePending {
            return "PHASE \(engine.state.completedPhaseNumber)\nCOMPLETED"
        }
        // During phase announcement — show phase title
        if let _ = engine.state.phaseAnnouncementStartBeat {
            return phaseAnnouncementText
        }
        // Screensaver — nothing
        if engine.isScreensaverMode { return nil }
        // Revealed notes for sequential / random
        let text = engine.revealedNotesText
        return text.isEmpty ? nil : text
    }

    private var phaseAnnouncementText: String {
        let p = engine.state.currentPhaseNumber
        let style: String
        switch engine.lessonStyle {
        case .sequential: style = "SEQUENTIAL"
        case .random:     style = "RANDOM"
        case .chord:      style = "CHORD"
        }
        let direction = engine.isDescendingPhase ? "DESCENDING" : "ASCENDING"
        return "PHASE \(p)\n\(style)\n\(direction)"
    }
}
