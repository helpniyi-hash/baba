import SwiftUI

public enum BabciaFontName {
    public static let regular = "LinLibertine"
    public static let bold = "LinLibertineB"
    public static let italic = "LinLibertineI"
    public static let boldItalic = "LinLibertineBI"
}

public enum BabciaFontToken {
    case displayLg
    case displayMd
    case displaySm
    case headingLg
    case headingMd
    case headingSm
    case bodyLg
    case bodyMd
    case bodySm
    case labelLg
    case labelMd
    case labelSm
    case caption
    case captionBold
}

public extension Font {
    static func babcia(_ token: BabciaFontToken) -> Font {
        switch token {
        case .displayLg:
            return .custom(BabciaFontName.bold, size: 40, relativeTo: .largeTitle)
        case .displayMd:
            return .custom(BabciaFontName.bold, size: 34, relativeTo: .largeTitle)
        case .displaySm:
            return .custom(BabciaFontName.bold, size: 28, relativeTo: .title)
        case .headingLg:
            return .custom(BabciaFontName.bold, size: 24, relativeTo: .title2)
        case .headingMd:
            return .custom(BabciaFontName.bold, size: 20, relativeTo: .title3)
        case .headingSm:
            return .custom(BabciaFontName.bold, size: 17, relativeTo: .headline)
        case .bodyLg:
            return .custom(BabciaFontName.regular, size: 17, relativeTo: .body)
        case .bodyMd:
            return .custom(BabciaFontName.regular, size: 15, relativeTo: .subheadline)
        case .bodySm:
            return .custom(BabciaFontName.regular, size: 13, relativeTo: .footnote)
        case .labelLg:
            return .custom(BabciaFontName.bold, size: 15, relativeTo: .subheadline)
        case .labelMd:
            return .custom(BabciaFontName.bold, size: 13, relativeTo: .footnote)
        case .labelSm:
            return .custom(BabciaFontName.bold, size: 11, relativeTo: .caption2)
        case .caption:
            return .custom(BabciaFontName.regular, size: 12, relativeTo: .caption)
        case .captionBold:
            return .custom(BabciaFontName.bold, size: 12, relativeTo: .caption)
        }
    }

    static let babciaLargeTitle = Font.babcia(.displayMd)
    static let babciaTitle = Font.babcia(.displaySm)
    static let babciaTitle2 = Font.babcia(.headingLg)
    static let babciaHeadline = Font.babcia(.headingSm)
    static let babciaBody = Font.babcia(.bodyLg)
    static let babciaCallout = Font.babcia(.bodyMd)
    static let babciaCaption = Font.babcia(.caption)
}
