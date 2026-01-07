//
//  CustomTextField.swift
//  Common
//
//  Created by Prank on 17/9/25.
//

import SwiftUI

public struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false

    public init(placeholder: String, text: Binding<String>, isSecure: Bool = false) {
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
    }

    public var body: some View {
        Group {
            if isSecure {
                BabciaSecureField(placeholder, text: $text)
            } else {
                BabciaTextField(placeholder, text: $text)
            }
        }
    }
}
