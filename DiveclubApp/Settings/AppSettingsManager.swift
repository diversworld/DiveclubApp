//
//  AppSettingsManager.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import SwiftUI
import Combine

@MainActor
class AppSettingsManager: ObservableObject {
    
    static let shared = AppSettingsManager()
    
    @Published var timeout: TimeInterval
    @Published var baseURL: String
    
    private init() {
        
        // Timeout laden
        let storedTimeout = UserDefaults.standard.double(forKey: "appTimeout")
        self.timeout = storedTimeout == 0 ? 120 : storedTimeout
        
        // BaseURL laden
        self.baseURL =
            UserDefaults.standard.string(forKey: "baseURL")
            ?? "https://contao56.ddev.site/api"
    }
    
    // MARK: - Persistenz
    
    func updateTimeout(_ value: TimeInterval) {
        timeout = value
        UserDefaults.standard.set(value, forKey: "appTimeout")
    }
    
    func updateBaseURL(_ value: String) {
        baseURL = value
        UserDefaults.standard.set(value, forKey: "baseURL")
    }
    
    // MARK: - Validierung
    
    func isValidURL(_ string: String) -> Bool {
        guard let url = URL(string: string),
              url.scheme == "https",
              url.host != nil else {
            return false
        }
        return true
    }
}
