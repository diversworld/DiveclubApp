//
//  ChangePasswordView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import SwiftUI

struct ChangePasswordView: View {
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var vm = ProfileViewModel()
    
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    
    @State private var authFailed = false
    
    var strength: PasswordStrength {
        PasswordValidator.evaluate(newPassword)
    }
    
    var body: some View {
        Form {
            
            Section("Aktuelles Passwort") {
                PasswordField(
                    title: "Aktuelles Passwort",
                    text: $currentPassword
                )
            }
            
            Section("Neues Passwort") {
                PasswordField(
                    title: "Neues Passwort",
                    text: $newPassword
                )
                
                PasswordStrengthView(password: newPassword)
            }
            
            Section("Bestätigung") {
                PasswordField(
                    title: "Passwort bestätigen",
                    text: $confirmPassword
                )
            }
            
            Section {
                Button("Passwort ändern") {
                    Task {
                        await secureChangePassword()
                    }
                }
                .disabled(!isValid)
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("Passwort ändern")
        .alert("Authentifizierung fehlgeschlagen",
               isPresented: $authFailed) {
            Button("OK", role: .cancel) { }
        }
    }
    
    var isValid: Bool {
        newPassword == confirmPassword &&
        strength.rawValue >= 2
    }
    
    private func secureChangePassword() async {
        
        //let success = await BiometricAuth.authenticate(
        //    reason: "Bestätige die Passwortänderung mit Face ID"
        //)
        
        //if success {
            await vm.changePassword(
                current: currentPassword,
                new: newPassword
            )
            dismiss()
        //} else {
        //    authFailed = true
        //}
    }
}


