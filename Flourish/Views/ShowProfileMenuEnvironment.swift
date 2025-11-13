import SwiftUI

// Environment key for profile menu
struct ShowProfileMenuKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false)
}

extension EnvironmentValues {
    var showProfileMenu: Binding<Bool> {
        get { self[ShowProfileMenuKey.self] }
        set { self[ShowProfileMenuKey.self] = newValue }
    }
}
