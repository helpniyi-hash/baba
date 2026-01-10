import SwiftUI
import Common

/// Locked-down spacing and layout constants for Babcia app
/// Following Apple's Landmarks app pattern for consistent spacing
/// References existing BabciaSpacing to ensure consistency
enum BabciaConstants {
    // MARK: - Spacing
    enum Spacing {
        // Reference existing spacing values from BabciaSpacing
        static let xxs = BabciaSpacing.xxs
        static let xs = BabciaSpacing.xs
        static let sm = BabciaSpacing.sm
        static let md = BabciaSpacing.md
        static let lg = BabciaSpacing.lg
        static let xl = BabciaSpacing.xl
        static let xxl = BabciaSpacing.xxl
        static let xxxl = BabciaSpacing.xxxl
        
        // Standard gaps
        static let cardGap = BabciaSpacing.cardGap
        static let sectionGap = BabciaSpacing.sectionGap
        
        // Padding
        static let screenPadding = BabciaSpacing.screenHorizontal
        static let cardPadding = BabciaSpacing.cardPadding
    }
    
    // MARK: - Sizing
    enum Size {
        static let heroImageHeight: CGFloat = 300
        static let heroImageMaxHeight: CGFloat = 420
        static let minTouchTarget: CGFloat = 44
    }
    
    // MARK: - Corner Radius
    enum Corner {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let full: CGFloat = 999
        
        static let card: CGFloat = lg
        static let badge: CGFloat = full
    }
}
