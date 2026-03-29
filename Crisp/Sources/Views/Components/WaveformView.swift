import SwiftUI

struct WaveformView: View {
    let levels: [CGFloat]
    let isAnimating: Bool
    let barCount: Int

    init(levels: [CGFloat], isAnimating: Bool, barCount: Int = 28) {
        self.levels = levels
        self.isAnimating = isAnimating
        self.barCount = barCount
    }

    private let gradient = LinearGradient(
        colors: [
            DesignTokens.accent,
            DesignTokens.accentAmber,
            DesignTokens.accentOrange
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .center, spacing: 3) {
                ForEach(0..<barCount, id: \.self) { index in
                    WaveformBar(
                        level: index < levels.count ? levels[index] : 0.05,
                        gradient: gradient,
                        isAnimating: isAnimating
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct WaveformBar: View {
    let level: CGFloat
    let gradient: LinearGradient
    let isAnimating: Bool

    @State private var animatedLevel: CGFloat = 0.05

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(gradient)
            .frame(height: barHeight)
            .animation(DesignTokens.spring, value: animatedLevel)
            .onChange(of: level) { _, newValue in
                animatedLevel = newValue
            }
            .onAppear {
                animatedLevel = level
            }
    }

    private var barHeight: CGFloat {
        let minHeight: CGFloat = 4
        let maxHeight: CGFloat = 56
        return minHeight + (maxHeight - minHeight) * animatedLevel
    }
}
