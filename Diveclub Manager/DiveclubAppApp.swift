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

    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainTabView()
                    .environmentObject(auth)
                    .environmentObject(settings)

                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(999)
                }
            }
            .task {
                await auth.bootstrap()

                // optional: kleine Mindestanzeigezeit, damit es nicht "blinkt"
                try? await Task.sleep(nanoseconds: 450_000_000)

                withAnimation(.easeOut(duration: 0.35)) {
                    showSplash = false
                }
            }
        }
    }
}
