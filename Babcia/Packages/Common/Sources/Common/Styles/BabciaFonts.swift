import SwiftUI

public extension Font {
    // Linux Libertine - use specific PostScript names per weight
    // Regular: LinLibertine, Bold: LinLibertineB
    static let babciaLargeTitle = Font.custom("LinLibertineB", size: 34, relativeTo: .largeTitle)
    static let babciaTitle = Font.custom("LinLibertineB", size: 28, relativeTo: .title)
    static let babciaTitle2 = Font.custom("LinLibertineB", size: 22, relativeTo: .title2)
    static let babciaHeadline = Font.custom("LinLibertineB", size: 17, relativeTo: .headline)
    static let babciaBody = Font.custom("LinLibertine", size: 17, relativeTo: .body)
    static let babciaCallout = Font.custom("LinLibertine", size: 16, relativeTo: .callout)
    static let babciaCaption = Font.custom("LinLibertine", size: 13, relativeTo: .caption)
}
