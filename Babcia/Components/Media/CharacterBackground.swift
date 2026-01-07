import SwiftUI
import Core

struct CharacterBackground: View {
    let character: BabciaCharacter
    @State private var assetName = ""

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if !assetName.isEmpty {
                    Image(assetName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } else {
                    Color(.systemBackground)
                }
            }
            .onAppear {
                if assetName.isEmpty {
                    assetName = character.fullBodyAssetNames.randomElement()
                        ?? character.assetName(for: .fullBodyHappy)
                }
            }
        }
    }
}
