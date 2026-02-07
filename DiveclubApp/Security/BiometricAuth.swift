//
//  BiometricAuth.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import LocalAuthentication

struct BiometricAuth {
    
    static func authenticate(reason: String) async -> Bool {
        
        let context = LAContext()
        var authError: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authError) {
            
            do {
                return try await context.evaluatePolicy(
                    .deviceOwnerAuthentication,
                    localizedReason: reason
                )
            } catch {
                print("Auth Error:", error.localizedDescription)
                return false
            }
            
        } else {
            if let authError {
                print("Biometrie nicht verfügbar:", authError.localizedDescription)
            }
            return false
        }
    }
}
