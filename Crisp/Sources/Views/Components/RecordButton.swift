import SwiftUI

struct RecordButton: View {
    let isRecording: Bool
    let action: () -> Void

    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.0

    private let buttonSize: CGFloat = 72

    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer pulse ring
                Circle()
                    .fill(DesignTokens.accent.opacity(pulseOpacity))
                    .frame(width: buttonSize + 24, height: buttonSize + 24)
                    .scaleEffect(pulseScale)

                // Main button
                Circle()
                    .fill(
                        isRecording
                            ? DesignTokens.accent
                            : DesignTokens.surface
                    )
                    .frame(width: buttonSize, height: buttonSize)
                    .overlay(
                        Circle()
                            .stroke(DesignTokens.accent, lineWidth: 2)
                    )

                // Inner icon
                if isRecording {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignTokens.background)
                        .frame(width: 22, height: 22)
                } else {
                    Circle()
                        .fill(DesignTokens.accent)
                        .frame(width: 24, height: 24)
                }
            }
        }
        .buttonStyle(.plain)
        .onChange(of: isRecording) { _, newValue in
            if newValue {
                startPulseAnimation()
            } else {
                stopPulseAnimation()
            }
        }
    }

    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            pulseScale = 1.3
            pulseOpacity = 0.3
        }
    }

    private func stopPulseAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            pulseScale = 1.0
            pulseOpacity = 0.0
        }
    }
}
