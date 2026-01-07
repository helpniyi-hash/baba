import SwiftUI

public enum BabciaAvatarSize {
    case xs
    case sm
    case md
    case lg
    case xl
    case xxl
    case huge

    var dimension: CGFloat {
        switch self {
        case .xs: return BabciaSize.avatarXs
        case .sm: return BabciaSize.avatarSm
        case .md: return BabciaSize.avatarMd
        case .lg: return BabciaSize.avatarLg
        case .xl: return BabciaSize.avatarXl
        case .xxl: return BabciaSize.avatarXxl
        case .huge: return BabciaSize.avatarHuge
        }
    }
}

public struct BabciaAvatar: View {
    private let image: Image?
    private let size: BabciaAvatarSize
    private let ringColor: Color?
    private let usesGlass: Bool

    public init(image: Image?, size: BabciaAvatarSize = .md, ringColor: Color? = nil, usesGlass: Bool = false) {
        self.image = image
        self.size = size
        self.ringColor = ringColor
        self.usesGlass = usesGlass
    }

    public var body: some View {
        let shape = Circle()
        ZStack {
            if let image {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                shape.fill(Color.white.opacity(BabciaOpacity.faint))
            }
        }
        .frame(width: size.dimension, height: size.dimension)
        .clipShape(shape)
        .overlay(
            shape.stroke(ringColor ?? .clear, lineWidth: ringColor == nil ? 0 : 2)
        )
        .background {
            if usesGlass {
                shape
                    .babciaGlassEffect(.clear, in: shape)
            }
        }
    }
}
