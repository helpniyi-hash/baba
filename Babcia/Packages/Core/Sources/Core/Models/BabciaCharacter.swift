import Foundation

public enum BabciaCharacter: String, CaseIterable, Codable, Identifiable, Sendable {
    case classic
    case baroness
    case toughLifecoach
    case warrior
    case wellnessX

    public var id: String { rawValue }

    public enum ImageRole: String, CaseIterable, Codable, Sendable {
        case fullBodyHappy
        case fullBodySad
        case fullBodyVictory
        case portraitHappy
        case portraitSad
        case portraitThinking
        case headshotNeutral
        case referenceNormalizedFull
    }

    public var displayName: String {
        switch self {
        case .classic:
            return "Babcia"
        case .baroness:
            return "The Baroness"
        case .toughLifecoach:
            return "Tough Lifecoach"
        case .warrior:
            return "Warrior Babcia"
        case .wellnessX:
            return "Wellness-X"
        }
    }

    public var tagline: String {
        switch self {
        case .classic:
            return "Guilt with love"
        case .baroness:
            return "Old money shade"
        case .toughLifecoach:
            return "Fixes your mess"
        case .warrior:
            return "Attack the mess"
        case .wellnessX:
            return "Baymax vibes"
        }
    }

    public var description: String {
        switch self {
        case .classic:
            return "Your traditional Polish grandmother who just stopped by with food and happened to notice everything."
        case .baroness:
            return "Elegance personified. She is not mad, just disappointed in a very expensive way."
        case .toughLifecoach:
            return "Direct, competent, and relentless about getting it done."
        case .warrior:
            return "Every cleaning task is an epic quest. Your mess is the final boss."
        case .wellnessX:
            return "Gentle robot companion. No judgment, just systematic support."
        }
    }

    public var voiceGuidance: String {
        switch self {
        case .classic:
            return "Speak like a loving Polish grandmother. Use 'Oj' and gentle guilt. Mention that you brought food. Be warm but notice everything."
        case .baroness:
            return "Speak with refined aristocratic disappointment. Use 'darling' and subtle shade."
        case .toughLifecoach:
            return "Speak like an efficient office manager. Be direct, slightly exasperated."
        case .warrior:
            return "Speak like a battle commander. Use caps for emphasis. Treat cleaning as an epic quest."
        case .wellnessX:
            return "Speak like a calm robot companion. Use 'initiating' and 'protocol'."
        }
    }

    public var voiceSamples: [String] {
        switch self {
        case .classic:
            return [
                "Oj, just a few little things...",
                "I brought pierogi, then we clean.",
                "Your babcia is so proud of you.",
                "Come, eat first. Then we clean."
            ]
        case .baroness:
            return [
                "This simply will not do, darling.",
                "One must maintain standards.",
                "How quaint.",
                "Excellence is a habit."
            ]
        case .toughLifecoach:
            return [
                "Let's get this handled.",
                "I made a list. You're welcome.",
                "What happened here?",
                "Clean by 2:45."
            ]
        case .warrior:
            return [
                "Attack the dishes.",
                "No mercy for dust bunnies.",
                "Today, we conquer.",
                "Your bedroom is a worthy opponent."
            ]
        case .wellnessX:
            return [
                "Initiating calm protocol.",
                "Start with one small task.",
                "I detect three items requiring attention.",
                "Excellent progress, human friend."
            ]
        }
    }

    public func randomVoiceSample() -> String {
        voiceSamples.randomElement() ?? "Hello."
    }

    public func assetName(for role: ImageRole) -> String {
        let prefix: String
        switch self {
        case .classic:
            prefix = "R1_Classic"
        case .baroness:
            prefix = "R2_Baroness"
        case .warrior:
            prefix = "R3_Warrior"
        case .wellnessX:
            prefix = "R4_Wellness"
        case .toughLifecoach:
            prefix = "R5_ToughLifecoach"
        }

        switch role {
        case .fullBodyHappy:
            return "\(prefix)_FullBody_Happy"
        case .fullBodySad:
            return "\(prefix)_FullBody_SadDisappointed"
        case .fullBodyVictory:
            return "\(prefix)_FullBody_Victory"
        case .portraitHappy:
            return "\(prefix)_Portrait_Happy"
        case .portraitSad:
            return "\(prefix)_Portrait_SadDisappointed"
        case .portraitThinking:
            return "\(prefix)_Portrait_Thinking"
        case .headshotNeutral:
            return "\(prefix)_Headshot_Neutral"
        case .referenceNormalizedFull:
            return "\(prefix)_Reference_NormalizedFull"
        }
    }

    public var portraitAssetName: String {
        assetName(for: .portraitHappy)
    }

    public var headshotAssetName: String {
        assetName(for: .headshotNeutral)
    }

    public var fullBodyAssetNames: [String] {
        [
            assetName(for: .fullBodyHappy),
            assetName(for: .fullBodyVictory),
            assetName(for: .fullBodySad)
        ]
    }

    public var accentHex: String {
        switch self {
        case .classic:
            return "8B4513"
        case .baroness:
            return "9B59B6"
        case .toughLifecoach:
            return "3498DB"
        case .warrior:
            return "E74C3C"
        case .wellnessX:
            return "1ABC9C"
        }
    }

    public var dreamVisionPrompt: String {
        switch self {
        case .classic:
            return """
            2. STYLE (Medium: Traditional Chinese Paper Cut):
               - Medium: Intricate red paper cutting (jianzhi)
               - Colors: Red paper on white background
               - Texture: Delicate cut paper with fine details
               - Style: Traditional Chinese folk art, silhouette
            """
        case .baroness:
            return """
            2. STYLE (Medium: Victorian Oil Painting):
               - Medium: Elegant Victorian oil painting aesthetic
               - Colors: Rich jewel tones - burgundy, gold, emerald, royal purple
               - Lighting: Dramatic golden hour warmth with visible brushstrokes
               - Finish: Luxurious painterly texture, aristocratic atmosphere
            """
        case .toughLifecoach:
            return """
            2. STYLE (Medium: Ink and Watercolor Illustration):
               - Medium: Hand-drawn ink line art with watercolor wash
               - Line Work: Clean black ink outlines, architectural style
               - Colors: Soft watercolor washes - sage green, warm beige, dusty rose
               - Finish: Visible paper texture, artistic hand-drawn quality
            """
        case .warrior:
            return """
            2. STYLE (Medium: Art Deco Illustration):
               - Medium: Bold Art Deco poster style
               - Colors: Gold, black, cream, deep teal
               - Style: Geometric shapes, bold lines, 1920s glamour
               - Mood: Luxurious, powerful, dramatic
            """
        case .wellnessX:
            return """
            2. STYLE (Medium: 1950s Retro Advertisement):
               - Medium: Vintage 1950s magazine advertisement
               - Colors: Bright cheerful pastels and primary colors
               - Style: Clean mid-century modern illustration
               - Mood: Optimistic, bright, Atomic Age aesthetic
            """
        }
    }

    public var verificationModeName: String {
        switch self {
        case .classic:
            return "Supportive"
        case .baroness:
            return "Ruthless"
        case .toughLifecoach:
            return "Hard"
        case .warrior:
            return "Standard"
        case .wellnessX:
            return "Trusted"
        }
    }

    public var verificationConfidenceThreshold: Double {
        switch self {
        case .classic:
            return 0.3
        case .baroness:
            return 0.7
        case .toughLifecoach:
            return 0.6
        case .warrior:
            return 0.45
        case .wellnessX:
            return 0.2
        }
    }

    public var verificationModeDescription: String {
        switch self {
        case .classic:
            return "Gentle and encouraging. Progress counts, not perfection."
        case .baroness:
            return "Uncompromising standards. Evidence must be unmistakable."
        case .toughLifecoach:
            return "Direct and demanding. Solid proof beats excuses."
        case .warrior:
            return "Focused and balanced. Clear progress wins."
        case .wellnessX:
            return "Trust-first and calm. Gentle accountability."
        }
    }
}
