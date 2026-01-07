import SwiftUI

public struct BabciaPrimaryButton: View {
    private let title: String
    private let action: () -> Void
    private let isLoading: Bool

    public init(_ title: String, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: BabciaSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                Text(title)
                    .font(.babcia(.labelLg))
            }
            .foregroundColor(.white)
            .babciaFullWidth()
            .padding(.vertical, BabciaSpacing.md)
            .padding(.horizontal, BabciaSpacing.lg)
        }
        .disabled(isLoading)
        .tint(.blue)
        .babciaGlassButtonProminent()
        .babciaTouchTarget(min: BabciaSize.touchLarge)
    }
}

public struct BabciaSecondaryButton: View {
    private let title: String
    private let action: () -> Void

    public init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.babcia(.labelLg))
                .babciaFullWidth()
                .padding(.vertical, BabciaSpacing.md)
                .padding(.horizontal, BabciaSpacing.lg)
        }
        .babciaGlassButton()
        .babciaTouchTarget(min: BabciaSize.touchComfortable)
    }
}

public struct BabciaIconButton: View {
    private let systemName: String
    private let action: () -> Void
    private let tint: Color
    private let size: CGFloat

    public init(systemName: String, tint: Color = .accentColor, size: CGFloat = BabciaSize.buttonMd, action: @escaping () -> Void) {
        self.systemName = systemName
        self.tint = tint
        self.size = size
        self.action = action
    }

    public var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                button
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .clipShape(Circle())
            } else {
                button
                    .buttonStyle(.bordered)
                    .clipShape(Circle())
            }
        }
        .tint(tint)
        .babciaTouchTarget()
        .accessibilityLabel(Text(systemName))
    }

    private var button: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: BabciaSize.iconMd, weight: .semibold))
                .frame(width: size, height: size)
        }
    }
}
