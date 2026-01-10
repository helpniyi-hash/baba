import SwiftUI

/// Locked-down spacing and layout constants for Babcia app
/// Following Apple's Landmarks app pattern for consistent spacing
enum BabciaConstants {
    // MARK: - Spacing
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 40
        
        // Standard gaps
        static let cardGap: CGFloat = md
        static let sectionGap: CGFloat = xl
        
        // Padding
        static let screenPadding: CGFloat = md
        static let cardPadding: CGFloat = md
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
