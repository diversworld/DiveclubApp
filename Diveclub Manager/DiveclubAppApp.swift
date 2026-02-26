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
    @StateObject private var settings = AppSettingsManager.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(auth)
                .environmentObject(settings)
                .task {
                    await auth.bootstrap()
                }
        }
    }
}
