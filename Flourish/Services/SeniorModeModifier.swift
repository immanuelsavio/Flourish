//
//  SeniorModeModifier.swift
//  Flourish
//
//  View modifier for senior mode text scaling
//

import SwiftUI

struct SeniorModeModifier: ViewModifier {
    @EnvironmentObject var appSettings: AppSettings
    let style: Font.TextStyle
    
    func body(content: Content) -> some View {
        content
            .font(.system(style, design: .default))
            .dynamicTypeSize(appSettings.seniorMode ? .accessibility3 : .large)
    }
}

extension View {
    func seniorText(_ style: Font.TextStyle = .body) -> some View {
        modifier(SeniorModeModifier(style: style))
    }
}
