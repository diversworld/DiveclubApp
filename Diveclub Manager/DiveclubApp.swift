//
//  DiveclubAppApp.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import SwiftUI

@main
struct DiveclubApp: App {

    @StateObject private var auth = AuthManager.shared
    @StateObject private var settings = AppSettingsManager.shared

    @State private var showSplash = true
    @State private var didRunBootstrap = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainTabView()
                    .environmentObject(auth)
                    .environmentObject(settings)
                    .opacity(showSplash ? 0 : 1)
                    .animation(.easeOut(duration: 0.45), value: showSplash)

                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(999)
                }
            }
            .task {
                guard !didRunBootstrap else { return }
                didRunBootstrap = true

                async let boot: Void = auth.bootstrap()

                // ✅ Splash MIN Zeit (länger)
                do { try await Task.sleep(nanoseconds: 2_200_000_000) } catch {}

                // ✅ Warte zusätzlich auf bootstrap (wenn du nicht warten willst: diese Zeile entfernen)
                await boot

                withAnimation(.easeOut(duration: 0.55)) {
                    showSplash = false
                }
            }
        }
    }
}
