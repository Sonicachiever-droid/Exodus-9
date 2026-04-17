import SwiftUI

// MARK: - Startup Sequence View (extracted from BeginnerGameplayView)

struct StartupSequenceView: View {
    enum Phase {
        case systemOnline
        case phaseOne
        case armed
    }

    let elapsed: TimeInterval
    let showFullSequence: Bool
    let armedText: String

    init(elapsed: TimeInterval, showFullSequence: Bool = true, armedText: String = "Memorization Sequence Armed") {
        self.elapsed = elapsed
        self.showFullSequence = showFullSequence
        self.armedText = armedText
    }

    var body: some View {
        let s = Self.state(for: elapsed, showFullSequence: showFullSequence, armedText: armedText)
        let fontSize: CGFloat = s.phase == .armed ? 29.6 : 34

        Text(s.text)
            .font(.system(size: fontSize, weight: .black, design: .monospaced))
            .foregroundStyle(s.color)
            .minimumScaleFactor(0.3)
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .shadow(color: s.color.opacity(0.95), radius: 14, x: 0, y: 0)
            .shadow(color: s.color.opacity(0.6), radius: 26, x: 0, y: 0)
            .opacity(s.isVisible ? 1 : 0)
    }

    static func state(
        for elapsed: TimeInterval,
        showFullSequence: Bool = true,
        armedText: String = "Memorization Sequence Armed"
    ) -> (text: String, color: Color, isVisible: Bool, phase: Phase) {
        let firstFlashPeriod: TimeInterval  = 1.0
        let secondFlashPeriod: TimeInterval = 1.0
        let armedFlashPeriod: TimeInterval  = 1.0
        let firstBlockDuration  = firstFlashPeriod  * 4
        let secondBlockDuration = firstBlockDuration + (secondFlashPeriod * 4)

        if !showFullSequence {
            let isVisible = Int(elapsed / armedFlashPeriod).isMultiple(of: 2)
            return (armedText, Color.green.opacity(0.98), isVisible, .armed)
        }
        if elapsed < firstBlockDuration {
            let isVisible = Int(elapsed / firstFlashPeriod).isMultiple(of: 2)
            return ("SYSTEM ONLINE", Color.orange.opacity(0.98), isVisible, .systemOnline)
        }
        if elapsed < secondBlockDuration {
            let local = elapsed - firstBlockDuration
            let isVisible = Int(local / secondFlashPeriod).isMultiple(of: 2)
            return ("PHASE 1", Color.red.opacity(0.98), isVisible, .phaseOne)
        }
        let local = elapsed - secondBlockDuration
        let isVisible = Int(local / armedFlashPeriod).isMultiple(of: 2)
        return (armedText, Color.green.opacity(0.98), isVisible, .armed)
    }
}
