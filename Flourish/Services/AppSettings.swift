//
//  AppSettings.swift
//  Flourish
//
//  Manager for app-wide settings (theme, text size, etc.)
//

import SwiftUI
import Combine

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @Published var colorScheme: ColorSchemeOption {
        didSet {
            UserDefaults.standard.set(colorScheme.rawValue, forKey: "colorScheme")
            objectWillChange.send()
        }
    }
    
    @Published var seniorMode: Bool {
        didSet {
            UserDefaults.standard.set(seniorMode, forKey: "seniorMode")
            objectWillChange.send()
        }
    }
    
    private init() {
        // Load color scheme
        if let savedScheme = UserDefaults.standard.string(forKey: "colorScheme"),
           let scheme = ColorSchemeOption(rawValue: savedScheme) {
            self.colorScheme = scheme
        } else {
            self.colorScheme = .system
        }
        
        // Load senior mode
        self.seniorMode = UserDefaults.standard.bool(forKey: "seniorMode")
    }
    
    // Get the actual color scheme to apply
    var appliedColorScheme: ColorScheme? {
        switch colorScheme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
    
    // Get font scale based on senior mode
    var fontScale: CGFloat {
        seniorMode ? 1.3 : 1.0
    }
    
    // Helper to get scaled font size
    func fontSize(_ baseSize: CGFloat) -> CGFloat {
        baseSize * fontScale
    }
}

enum ColorSchemeOption: String, CaseIterable, Hashable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var displayName: String {
        self.rawValue
    }
}

// Extension to make ColorSchemeOption identifiable
extension ColorSchemeOption: Identifiable {
    var id: String { rawValue }
}
