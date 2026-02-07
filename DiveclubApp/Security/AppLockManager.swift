//
//  AppLockManager.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import SwiftUI
import Combine

@MainActor
class AppLockManager: ObservableObject {
    
    static let shared = AppLockManager()
    
    @Published var isLocked = false
    
    private var backgroundDate: Date?
    
    // Timeout in Sekunden (z.B. 120 = 2 Minuten)
    private var timeout: TimeInterval {
        AppSettingsManager.shared.timeout
    }
    
    private init() {}
    
    func appDidEnterBackground() {
        backgroundDate = Date()
    }
    
    func appDidBecomeActive() {
        guard let backgroundDate else { return }
        
        let elapsed = Date().timeIntervalSince(backgroundDate)
        
        if elapsed > timeout {
            isLocked = true
        }
    }
    
    func unlock() {
        isLocked = false
    }
}
