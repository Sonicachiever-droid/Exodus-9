import SwiftUI

// MARK: - Beginner Control Plate View
// START, RESET, AUTOPLAY toggle buttons.

struct BeginnerControlPlateView: View {
    let engine: BeginnerGameEngine
    let onStart: () -> Void
    let onReset: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Button("START") { onStart() }
                .frame(minWidth: 58, minHeight: 34, maxHeight: 34)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(engine.isRoundArmed
                              ? Color.green.opacity(0.85)
                              : Color.white.opacity(0.12))
                )
                .foregroundStyle(engine.isRoundArmed ? .black : .white)
                .fontWeight(.bold)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            Button("RESET") { onReset() }
                .frame(minWidth: 58, minHeight: 34, maxHeight: 34)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.12))
                )
                .foregroundStyle(.white)
                .fontWeight(.bold)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            Button(engine.state.autoPlayEnabled ? "AUTO ON" : "AUTO") {
                engine.state.autoPlayEnabled.toggle()
                if !engine.state.autoPlayEnabled {
                    engine.state.autoPlayNextDate = nil
                }
            }
            .frame(minWidth: 58, minHeight: 34, maxHeight: 34)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(engine.state.autoPlayEnabled
                          ? Color.cyan.opacity(0.75)
                          : Color.white.opacity(0.12))
            )
            .foregroundStyle(engine.state.autoPlayEnabled ? .black : .white)
            .fontWeight(.bold)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .font(.system(size: 13, weight: .bold, design: .monospaced))
    }
}
