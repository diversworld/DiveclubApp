//
//  DiveclubAppApp.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import SwiftUI

@main
struct DiveclubAppApp: App {

    @StateObject private var auth = AuthManager.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if auth.isLoading {
                    ProgressView("Session wird geprüft …")
                } else if auth.isLoggedIn {
                    MainTabView()
                } else {
                    StartView()
                }
            }
            .task {
                await auth.bootstrap()
            }
        }
    }
}
