import SwiftUI

/// Unified page template for all Babcia screens
/// Hero image at top with liquid glass content area below
/// Based on Breve coffee app style and Apple's Landmarks pattern
struct BabciaPageTemplate<Content: View>: View {
    let heroImage: Image
    let content: Content
    
    init(heroImage: Image, @ViewBuilder content: () -> Content) {
        self.heroImage = heroImage
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero image with background extension effect
                heroImage
                    .resizable()
                    .scaledToFill()
                    .backgroundExtensionEffectFallback()
                    .flexibleHeaderContent()
                
                // Glass content area
                VStack(spacing: BabciaConstants.Spacing.sectionGap) {
                    content
                }
                .padding(BabciaConstants.Spacing.screenPadding)
                .frame(maxWidth: .infinity)
                .glassEffectFallback()
                .clipShape(RoundedRectangle(cornerRadius: BabciaConstants.Corner.xl, style: .continuous))
                .offset(y: -BabciaConstants.Spacing.xl)
            }
        }
        .flexibleHeaderScrollView()
        .ignoresSafeArea(edges: .top)
    }
}
