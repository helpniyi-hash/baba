import SwiftUI
import Common

struct BabciaLoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(BabciaOpacity.scrim)
                .ignoresSafeArea()

            VStack(spacing: BabciaSpacing.md) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.1)

                Text("Loading...")
                    .font(.babcia(.headingSm))
                    .foregroundColor(.white)
            }
            .padding(BabciaSpacing.xxl)
            .babciaGlassCard(cornerRadius: BabciaCorner.card, shadow: .md, fullWidth: false)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading")
    }
}
