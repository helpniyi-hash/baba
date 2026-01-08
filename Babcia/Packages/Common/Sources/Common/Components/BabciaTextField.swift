import SwiftUI
import UIKit

public struct BabciaTextField: View {
    private let placeholder: String
    @Binding private var text: String
    private let keyboardType: UIKeyboardType
    private let textContentType: UITextContentType?
    private let capitalization: TextInputAutocapitalization?
    private let disableAutocorrection: Bool
    private let showsClearButton: Bool
    private let accentColor: Color?
    @FocusState private var isFocused: Bool

    public init(
        _ placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil,
        capitalization: TextInputAutocapitalization? = nil,
        disableAutocorrection: Bool = false,
        showsClearButton: Bool = true,
        accentColor: Color? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.keyboardType = keyboardType
        self.textContentType = textContentType
        self.capitalization = capitalization
        self.disableAutocorrection = disableAutocorrection
        self.showsClearButton = showsClearButton
        self.accentColor = accentColor
    }

    public var body: some View {
        HStack(spacing: BabciaSpacing.sm) {
            TextField(
                "",
                text: $text,
                prompt: Text(placeholder).foregroundStyle(.secondary)
            )
            .font(.babcia(.bodyLg))
            .foregroundStyle(.primary)
            .keyboardType(keyboardType)
            .textContentType(textContentType)
            .textInputAutocapitalization(capitalization)
            .autocorrectionDisabled(disableAutocorrection)
            .focused($isFocused)

            if showsClearButton && !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear text")
            }
        }
        .padding(.horizontal, BabciaSpacing.md)
        .frame(minHeight: BabciaSize.inputHeight)
        .background(fieldBackground)
        .overlay(fieldBorder)
        .scaleEffect(isFocused ? 1.01 : 1.0)
        .animation(BabciaAnimation.springSubtle, value: isFocused)
        .tint(accentColor ?? .accentColor)
        .babciaFullWidth()
    }

    @ViewBuilder
    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: BabciaCorner.input, style: .continuous)
            .fill(.thinMaterial)
    }

    private var fieldBorder: some View {
        RoundedRectangle(cornerRadius: BabciaCorner.input, style: .continuous)
            .stroke(Color.primary.opacity(isFocused ? 0.18 : 0.10), lineWidth: 1)
    }
}

public struct BabciaSecureField: View {
    private let placeholder: String
    @Binding private var text: String
    private let accentColor: Color?
    @State private var isSecure = true
    @FocusState private var isFocused: Bool

    public init(_ placeholder: String, text: Binding<String>, accentColor: Color? = nil) {
        self.placeholder = placeholder
        self._text = text
        self.accentColor = accentColor
    }

    public var body: some View {
        HStack(spacing: BabciaSpacing.sm) {
            Group {
                if isSecure {
                    SecureField(
                        "",
                        text: $text,
                        prompt: Text(placeholder).foregroundStyle(.secondary)
                    )
                } else {
                    TextField(
                        "",
                        text: $text,
                        prompt: Text(placeholder).foregroundStyle(.secondary)
                    )
                }
            }
            .font(.babcia(.bodyLg))
            .foregroundStyle(.primary)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .focused($isFocused)

            Button {
                isSecure.toggle()
            } label: {
                Image(systemName: isSecure ? "eye.slash.fill" : "eye.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isSecure ? "Show password" : "Hide password")
        }
        .padding(.horizontal, BabciaSpacing.md)
        .frame(minHeight: BabciaSize.inputHeight)
        .background(fieldBackground)
        .overlay(fieldBorder)
        .scaleEffect(isFocused ? 1.01 : 1.0)
        .animation(BabciaAnimation.springSubtle, value: isFocused)
        .tint(accentColor ?? .accentColor)
        .babciaFullWidth()
    }

    @ViewBuilder
    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: BabciaCorner.input, style: .continuous)
            .fill(.thinMaterial)
    }

    private var fieldBorder: some View {
        RoundedRectangle(cornerRadius: BabciaCorner.input, style: .continuous)
            .stroke(Color.primary.opacity(isFocused ? 0.18 : 0.10), lineWidth: 1)
    }
}
