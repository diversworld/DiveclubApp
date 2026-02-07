//
//  DiveclubAppApp.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import SwiftUI
import SwiftData

@main
struct DiveclubAppApp: App {
    
    @StateObject private var auth = AuthManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var lockManager = AppLockManager.shared
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                Group {
                    if auth.isCheckingSession {
                        ProgressView("Session wird geprüft…")
                    }
                    else if auth.isAuthenticated {
                        MainTabView()
                    }
                    else {
                        LoginView()
                    }
                }
                
                if lockManager.isLocked && auth.isAuthenticated {
                    LockView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .background:
                    lockManager.appDidEnterBackground()
                case .active:
                    lockManager.appDidBecomeActive()
                default:
                    break
                }
            }
            .task {
                await auth.checkSession()
            }
        }
    }
}
