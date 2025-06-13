import SwiftUI
import Foundation

class AppState: ObservableObject {
    @Published var isAuthenticated: Bool

    init() {
        self.isAuthenticated = UserDefaultsManager.shared.getJWTToken() != nil
    }

    func logout() {
        // Clear all user data including token
        UserDefaultsManager.shared.clearUserData()
        isAuthenticated = false
    }

    func loginSuccess() {
        isAuthenticated = true
    }
} 