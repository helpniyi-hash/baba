import CoreText
import os.log
import SwiftUI
import UIKit

public enum BabciaFontRegistrar {
    private static let logger = Logger(subsystem: "Babcia", category: "Fonts")

    public static func registerFonts() {
        guard let urls = Bundle.module.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts") else {
            logger.error("No font files found in Common resources Fonts/ directory.")
            return
        }

        for url in urls {
            var error: Unmanaged<CFError>?
            let success = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
            if !success {
                let message = error?.takeRetainedValue().localizedDescription ?? "Unknown registration error."
                logger.error("Failed to register font at \(url.lastPathComponent, privacy: .public): \(message, privacy: .public)")
                registerGraphicsFontFallback(url: url)
            } else {
                logger.debug("Registered font: \(url.lastPathComponent, privacy: .public)")
            }
        }

        verifyFontAvailability()
    }

    private static func registerGraphicsFontFallback(url: URL) {
        guard let data = try? Data(contentsOf: url) as CFData,
              let provider = CGDataProvider(data: data),
              let cgFont = CGFont(provider) else {
            logger.error("Failed to load font data for fallback registration: \(url.lastPathComponent, privacy: .public)")
            return
        }

        var error: Unmanaged<CFError>?
        if CTFontManagerRegisterGraphicsFont(cgFont, &error) {
            logger.debug("Registered font via graphics fallback: \(url.lastPathComponent, privacy: .public)")
        } else {
            let message = error?.takeRetainedValue().localizedDescription ?? "Unknown graphics registration error."
            logger.error("Graphics font registration failed for \(url.lastPathComponent, privacy: .public): \(message, privacy: .public)")
        }
    }

    private static func verifyFontAvailability() {
        let names = [
            BabciaFontName.regular,
            BabciaFontName.bold,
            BabciaFontName.italic,
            BabciaFontName.boldItalic
        ]
        for name in names {
            if UIFont(name: name, size: 12) == nil {
                logger.error("Font not available after registration: \(name, privacy: .public)")
            } else {
                logger.debug("Font available: \(name, privacy: .public)")
            }
        }
    }
}
