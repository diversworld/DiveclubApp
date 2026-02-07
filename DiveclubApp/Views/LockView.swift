//
//  LockView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import SwiftUI
import Combine

struct LockView: View {
    
    @ObservedObject var lockManager = AppLockManager.shared
    @State private var authFailed = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                
                Image(systemName: "lock.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
                
                Text("App gesperrt")
                    .font(.title2)
                    .foregroundColor(.white)
                
                Button("Entsperren") {
                    Task {
                        await unlock()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .alert("Authentifizierung fehlgeschlagen",
               isPresented: $authFailed) {
            Button("OK", role: .cancel) { }
        }
    }
    
    private func unlock() async {
        let success = await BiometricAuth.authenticate(
            reason: "Entsperre die App"
        )
        
        if success {
            lockManager.unlock()
        } else {
            authFailed = true
        }
    }
}

