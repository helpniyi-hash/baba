import SwiftUI
import Presentation
import Common
import Core

enum SetupStep: Int, CaseIterable {
    case welcome
    case character
    case apiKey
}

struct SetupView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var step: SetupStep = .welcome
    @State private var selectedCharacter: BabciaCharacter = .classic
    @State private var geminiKey = ""
    @State private var isValidating = false
    @State private var errorMessage: String?
    @State private var didPrefill = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                BabciaBackground(style: .character(selectedCharacter))

                ScrollView {
                    VStack(spacing: BabciaSpacing.sectionGap) {
                        Spacer(minLength: BabciaSpacing.huge)

                        SetupProgressDots(step: step)

                        switch step {
                        case .welcome:
                            setupCard {
                                VStack(spacing: BabciaSpacing.lg) {
                                    Text("Welcome home")
                                        .font(.babcia(.displaySm))
                                        .foregroundColor(.white)

                                    Text("Babcia keeps each room warm, tidy, and a little bit enchanted.")
                                        .font(.babcia(.bodyLg))
                                        .foregroundColor(.white.opacity(BabciaOpacity.strong))
                                        .multilineTextAlignment(.center)

                                    BabciaPrimaryButton("Meet the Babcias") {
                                        step = .character
                                    }
                                    .accessibilityLabel("Meet the Babcias")

                                    Button("Skip intro") {
                                        step = .apiKey
                                    }
                                    .font(.babcia(.labelMd))
                                    .foregroundColor(.white.opacity(BabciaOpacity.strong))
                                    .babciaGlassButton()
                                    .controlSize(.small)
                                    .accessibilityLabel("Skip intro")
                                }
                            }
                        case .character:
                            setupCard {
                                VStack(spacing: BabciaSpacing.lg) {
                                    Text("Choose your Babcia")
                                        .font(.babcia(.headingLg))
                                        .foregroundColor(.white)

                                    Text("Pick a character to guide your rooms. You can change this later.")
                                        .font(.babcia(.bodyLg))
                                        .foregroundColor(.white.opacity(BabciaOpacity.strong))
                                        .multilineTextAlignment(.center)

                                    CharacterPicker(selectedCharacter: $selectedCharacter)

                                    BabciaPrimaryButton("Continue") {
                                        step = .apiKey
                                    }
                                    .accessibilityLabel("Continue")

                                    Button("Back") {
                                        step = .welcome
                                    }
                                    .font(.babcia(.labelMd))
                                    .foregroundColor(.white.opacity(BabciaOpacity.strong))
                                    .babciaGlassButton()
                                    .controlSize(.small)
                                    .accessibilityLabel("Back to welcome")
                                }
                            }
                        case .apiKey:
                            setupCard {
                                VStack(spacing: BabciaSpacing.lg) {
                                    Text("Connect Gemini")
                                        .font(.babcia(.headingLg))
                                        .foregroundColor(.white)

                                    Text("Enter your Gemini API key to unlock scans and tasks.")
                                        .font(.babcia(.bodyLg))
                                        .foregroundColor(.white.opacity(BabciaOpacity.strong))
                                        .multilineTextAlignment(.center)

                                    BabciaSecureField("Gemini API Key", text: $geminiKey)
                                        .foregroundColor(.white)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .accessibilityLabel("Gemini API key")

                                    if let errorMessage {
                                        Text(errorMessage)
                                            .font(.babcia(.caption))
                                            .foregroundColor(.red)
                                            .accessibilityLabel(errorMessage)
                                    }

                                    BabciaPrimaryButton(isValidating ? "Testing..." : "Test & Continue", isLoading: isValidating) {
                                        validateAndContinue()
                                    }
                                    .disabled(geminiKey.isEmpty || isValidating)
                                    .opacity(geminiKey.isEmpty ? BabciaOpacity.disabled : BabciaOpacity.opaque)
                                    .accessibilityLabel("Test Gemini key and continue")

                                    Button("Back") {
                                        step = .character
                                    }
                                    .font(.babcia(.labelMd))
                                    .foregroundColor(.white.opacity(BabciaOpacity.strong))
                                    .babciaGlassButton()
                                    .controlSize(.small)
                                    .accessibilityLabel("Back to character selection")
                                }
                            }
                        }

                        Spacer(minLength: BabciaSpacing.huge)
                    }
                    .frame(minHeight: geometry.size.height)
                    .babciaHorizontalPadding()
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            if !didPrefill {
                geminiKey = appViewModel.settings.geminiAPIKey
                selectedCharacter = appViewModel.settings.selectedCharacter
                didPrefill = true
            }
        }
    }

    @ViewBuilder
    private func setupCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .babciaCardPadding()
            .babciaGlassCard(style: .strong, cornerRadius: BabciaCorner.sheet, shadow: .lg)
            .babciaFullWidth()
    }

    private func validateAndContinue() {
        guard !geminiKey.isEmpty else { return }
        isValidating = true
        errorMessage = nil

        Task {
            let isValid = await appViewModel.validateGeminiKey(geminiKey)
            await MainActor.run {
                if isValid {
                    appViewModel.completeSetup(geminiKey: geminiKey, selectedCharacter: selectedCharacter)
                } else {
                    errorMessage = "Invalid API key"
                }
                isValidating = false
            }
        }
    }
}

struct SetupProgressDots: View {
    let step: SetupStep

    var body: some View {
        HStack(spacing: BabciaSpacing.sm) {
            ForEach(SetupStep.allCases, id: \.rawValue) { item in
                Circle()
                    .fill(item == step ? Color.white : Color.white.opacity(BabciaOpacity.medium))
                    .frame(
                        width: item == step ? BabciaSpacing.sm + 2 : BabciaSpacing.sm,
                        height: item == step ? BabciaSpacing.sm + 2 : BabciaSpacing.sm
                    )
            }
        }
        .accessibilityLabel("Setup progress")
        .accessibilityValue(Text("\(step.rawValue + 1) of \(SetupStep.allCases.count)"))
    }
}

struct CharacterPicker: View {
    @Binding var selectedCharacter: BabciaCharacter
    @Namespace private var characterNamespace

    var body: some View {
        BabciaGlassGroup(spacing: 30) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: BabciaSpacing.cardGap) {
                    ForEach(BabciaCharacter.allCases) { character in
                        Button {
                            selectedCharacter = character
                        } label: {
                            CharacterCard(character: character, isSelected: character == selectedCharacter)
                        }
                        .buttonStyle(BabciaSelectionButtonStyle(isSelected: character == selectedCharacter))
                        .accessibilityLabel("Select \(character.displayName)")
                        .accessibilityValue(Text(character == selectedCharacter ? "Selected" : "Not selected"))
                        .babciaInteractiveGlassEffect(.clear)
                        .babciaGlassEffectID(character.id, in: characterNamespace)
                    }
                }
                .padding(.vertical, BabciaSpacing.xs)
            }
        }
    }
}

struct CharacterCard: View {
    let character: BabciaCharacter
    let isSelected: Bool

    var body: some View {
        VStack(spacing: BabciaSpacing.sm) {
            Image(character.portraitAssetName)
                .resizable()
                .scaledToFill()
                .frame(width: 120, height: 160)
                .clipped()
                .cornerRadius(BabciaCorner.cardImage)

            VStack(spacing: BabciaSpacing.xxs) {
                Text(character.displayName)
                    .font(.babcia(.headingSm))
                    .foregroundColor(.white)

                Text(character.tagline)
                    .font(.babcia(.caption))
                    .foregroundColor(.white.opacity(BabciaOpacity.strong))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(BabciaSpacing.cardPaddingCompact)
        .background(Color.white.opacity(isSelected ? 0.2 : 0.1))
        .cornerRadius(BabciaCorner.card)
        .overlay(
            RoundedRectangle(cornerRadius: BabciaCorner.card)
                .stroke(Color.white.opacity(isSelected ? 0.6 : 0.2), lineWidth: 1)
        )
    }
}
