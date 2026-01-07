import SwiftUI
import Common

struct ProgressCard: View {
    let totalXP: Int
    let level: Int

    private var progress: Double {
        let baseXP = max(0, (level - 1) * 100)
        let currentXP = max(0, totalXP - baseXP)
        return min(1.0, Double(currentXP) / 100.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: BabciaSpacing.md) {
            Text("Your Progress")
                .font(.babcia(.headingSm))

            VStack(alignment: .leading, spacing: BabciaSpacing.sm) {
                HStack {
                    Text("XP to Next Level")
                        .font(.babcia(.caption))
                    Spacer()
                    Text("\(totalXP) / \(level * 100)")
                        .font(.babcia(.caption))
                        .contentTransition(.numericText())
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: BabciaCorner.sm)
                            .fill(Color.gray.opacity(BabciaOpacity.light))
                            .frame(height: BabciaSpacing.sm)

                        RoundedRectangle(cornerRadius: BabciaCorner.sm)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: BabciaSpacing.sm)
                    }
                }
                .frame(height: BabciaSpacing.sm)
            }
        }
        .babciaCardPadding()
        .babciaGlassCard()
        .babciaFullWidthLeading()
    }
}
