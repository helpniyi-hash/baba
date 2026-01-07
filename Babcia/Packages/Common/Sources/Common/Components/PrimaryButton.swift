//
//  PrimaryButton.swift
//  Common
//
//  Created by Prank on 17/9/25.
//

import SwiftUI

public struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    let isLoading: Bool

    public init(title: String, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text(title)
                        .font(.babcia(.labelLg))
                }
            }
            .babciaFullWidth()
            .padding(.vertical, BabciaSpacing.md)
            .padding(.horizontal, BabciaSpacing.lg)
            .foregroundColor(.white)
        }
        .disabled(isLoading)
        .tint(.blue)
        .babciaGlassButtonProminent()
        .babciaTouchTarget(min: BabciaSize.touchLarge)
    }
}
