import SwiftUI

/// Locked-down spacing and layout constants for Babcia app
/// Following Apple's Landmarks app pattern for consistent spacing
/// Aligned with existing BabciaSpacing values for compatibility
enum BabciaConstants {
    // MARK: - Spacing
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 6  // Aligned with BabciaSpacing.xs
        static let sm: CGFloat = 8  // Aligned with BabciaSpacing.sm
        static let md: CGFloat = 12  // Aligned with BabciaSpacing.md
        static let lg: CGFloat = 16  // Aligned with BabciaSpacing.lg
        static let xl: CGFloat = 20  // Aligned with BabciaSpacing.xl
        static let xxl: CGFloat = 24  // Aligned with BabciaSpacing.xxl
        static let xxxl: CGFloat = 32  // Aligned with BabciaSpacing.xxxl
        
        // Standard gaps
        static let cardGap: CGFloat = md  // 12
        static let sectionGap: CGFloat = xxl  // 24
        
        // Padding
        static let screenPadding: CGFloat = lg  // 16
        static let cardPadding: CGFloat = lg  // 16
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
