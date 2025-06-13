//
//  SchoolAppApp.swift
//  SchoolApp
//
//  Created by Ideas2IT on 10/06/25.
//

import SwiftUI

@main
struct SchoolAppApp: App {
    @StateObject var appState = AppState()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if appState.isAuthenticated {
                    HomeView()
                } else {
                    LoginView()
                }
            }
            .environmentObject(appState)
        }
    }
}
