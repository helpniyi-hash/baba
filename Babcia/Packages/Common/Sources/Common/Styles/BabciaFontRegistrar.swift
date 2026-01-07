import CoreText
import SwiftUI

public enum BabciaFontRegistrar {
    public static func registerFonts() {
        guard let urls = Bundle.module.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts") else {
            return
        }

        for url in urls {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
