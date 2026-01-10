import SwiftUI

/// Stub implementations for LiquidGlassKit components
/// These are placeholders until iOS 26 and the actual package are available

// MARK: - LiquidGlassButton
struct LiquidGlassButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void
    
    init(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            if let systemImage = systemImage {
                Label(title, systemImage: systemImage)
            } else {
                Text(title)
            }
        }
        .buttonStyle(.borderedProminent)
    }
}

// MARK: - LiquidGlassProminentButton
struct LiquidGlassProminentButton: View {
    let title: String
    let action: () -> Void
    
    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
        }
        .buttonStyle(.borderedProminent)
    }
}

// MARK: - LiquidGlassBadge
struct LiquidGlassBadge: View {
    let text: String
    let systemImage: String?
    
    init(_ text: String, systemImage: String? = nil) {
        self.text = text
        self.systemImage = systemImage
    }
    
    var body: some View {
        if let systemImage = systemImage {
            Label(text, systemImage: systemImage)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.regularMaterial)
                .clipShape(Capsule())
        } else {
            Text(text)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.regularMaterial)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Glass Effect Extensions
extension View {
    /// Fallback for .glassEffect() which requires iOS 26
    @ViewBuilder
    func glassEffectFallback() -> some View {
        if #available(iOS 18.0, *) {
            self.background(.regularMaterial)
        } else {
            self.background(.ultraThinMaterial)
        }
    }
    
    /// Fallback for .backgroundExtensionEffect() which requires iOS 26
    @ViewBuilder
    func backgroundExtensionEffectFallback() -> some View {
        self // No effect in fallback
    }
}
