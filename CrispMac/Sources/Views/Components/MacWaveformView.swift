import SwiftUI

// MARK: - Polished MacWaveformView (60fps smooth)
struct MacWaveformView: View {
    let levels: [CGFloat]
    let isAnimating: Bool
    let barCount: Int

    init(levels: [CGFloat], isAnimating: Bool, barCount: Int = 28) {
        self.levels = levels
        self.isAnimating = isAnimating
        self.barCount = barCount
    }

    private let waveformGradient = LinearGradient(
        colors: [DesignTokens.accent, DesignTokens.accentAmber],
        startPoint: .leading,
        endPoint: .trailing
    )

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .center, spacing: 4) {
                ForEach(0..<barCount, id: \.self) { index in
                    MacWaveformBar(
                        level: barLevel(at: index),
                        isAnimating: isAnimating,
                        isLive: isAnimating && index == barCount - 1
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func barLevel(at index: Int) -> CGFloat {
        guard index < levels.count else { return 0.05 }
        return max(0.05, levels[index])
    }
}

struct MacWaveformBar: View {
    let level: CGFloat
    let isAnimating: Bool
    let isLive: Bool

    private let waveformGradient = LinearGradient(
        colors: [DesignTokens.accent, DesignTokens.accentAmber],
        startPoint: .leading,
        endPoint: .trailing
    )

    // Use a fast, low-damping spring for snappy 60fps response
    private var barAnimation: SwiftUI.Animation {
        .spring(response: 0.12, dampingFraction: 0.7)
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(waveformGradient)
            .frame(height: barHeight)
            .animation(barAnimation, value: level)
            .opacity(isLive ? liveOpacity : 1.0)
            .animation(.easeInOut(duration: 0.3), value: isLive)
    }

    private var barHeight: CGFloat {
        let minHeight: CGFloat = 4
        let maxHeight: CGFloat = 64
        return minHeight + (maxHeight - minHeight) * level
    }

    private var liveOpacity: Double {
        isAnimating ? 1.0 : 0.7
    }
}

// MARK: - Sound Quality Indicator
struct SoundQualityIndicator: View {
    let level: Float
    let isRecording: Bool

    private var quality: Quality {
        guard isRecording else { return .idle }
        if level < 0.15 { return .low }
        if level < 0.45 { return .medium }
        return .high
    }

    enum Quality {
        case idle, low, medium, high

        var color: Color {
            switch self {
            case .idle: return DesignTokens.textSecondary.opacity(0.4)
            case .low: return DesignTokens.error
            case .medium: return DesignTokens.accentAmber
            case .high: return DesignTokens.accent
            }
        }

        var icon: String {
            switch self {
            case .idle: return "waveform"
            case .low: return "waveform.badge.exclamationmark"
            case .medium: return "waveform"
            case .high: return "waveform"
            }
        }

        var label: String {
            switch self {
            case .idle: return "Ready"
            case .low: return "Low"
            case .medium: return "Good"
            case .high: return "Excellent"
            }
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: quality.icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(quality.color)

            Text(quality.label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(quality.color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(quality.color.opacity(0.12))
        )
    }
}

// MARK: - Polished Record Button (more prominent)
struct MacRecordButton: View {
    let isRecording: Bool
    let action: () -> Void

    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.0
    @State private var innerScale: CGFloat = 1.0

    // 72pt button — prominent on any display
    private let buttonSize: CGFloat = 72

    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer glow ring (accent color halo when recording)
                Circle()
                    .fill(DesignTokens.accent.opacity(0.18))
                    .frame(width: buttonSize + 36, height: buttonSize + 36)
                    .scaleEffect(pulseScale)
                    .opacity(pulseOpacity)

                // Secondary pulse ring
                Circle()
                    .fill(DesignTokens.accent.opacity(0.25))
                    .frame(width: buttonSize + 20, height: buttonSize + 20)
                    .scaleEffect(pulseScale * 0.9)
                    .opacity(pulseOpacity * 0.8)

                // Main button body
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                isRecording ? DesignTokens.accent : DesignTokens.surface,
                                isRecording ? DesignTokens.accentAmber : DesignTokens.surface.opacity(0.9)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: buttonSize / 2
                        )
                    )
                    .frame(width: buttonSize, height: buttonSize)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [DesignTokens.accent, DesignTokens.accentOrange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isRecording ? 3 : 2
                            )
                    )
                    .shadow(color: DesignTokens.accent.opacity(isRecording ? 0.5 : 0.2), radius: isRecording ? 16 : 6)

                // Inner shape
                Group {
                    if isRecording {
                        // Stop square
                        RoundedRectangle(cornerRadius: 5)
                            .fill(DesignTokens.background)
                            .frame(width: 24, height: 24)
                            .scaleEffect(innerScale)
                    } else {
                        // Record circle
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [DesignTokens.accent, DesignTokens.accentAmber],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 26, height: 26)
                            .shadow(color: DesignTokens.accent.opacity(0.6), radius: 4)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(innerScale)
        .onChange(of: isRecording) { _, newValue in
            if newValue {
                startPulseAnimation()
            } else {
                stopPulseAnimation()
            }
        }
    }

    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            pulseScale = 1.25
            pulseOpacity = 1.0
        }
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            innerScale = 1.1
        }
    }

    private func stopPulseAnimation() {
        withAnimation(.easeOut(duration: 0.4)) {
            pulseScale = 1.0
            pulseOpacity = 0.0
            innerScale = 1.0
        }
    }
}
