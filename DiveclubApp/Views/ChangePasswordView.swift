//
//  ChangePasswordView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import SwiftUI

struct ChangePasswordView: View {
    
    @ObservedObject var vm: ProfileViewModel
    
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        Form {
            
            Section("Aktuelles Passwort") {
                SecureField("Aktuelles Passwort", text: $currentPassword)
            }
            
            Section("Neues Passwort") {
                SecureField("Neues Passwort", text: $newPassword)
                SecureField("Passwort bestätigen", text: $confirmPassword)
            }
            
            Button {
                Task {
                    await vm.changePassword(
                        current: currentPassword,
                        new: newPassword
                    )
                }
            } label: {
                if vm.isSaving {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Passwort ändern")
                        .frame(maxWidth: .infinity)
                }
            }
            .disabled(!canSubmit)
        }
        .navigationTitle("Passwort ändern")
        .overlay(alignment: .top) {
            if vm.saveSuccess {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Passwort erfolgreich geändert")
                }
                .padding()
                .background(.green)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()
                .transition(.move(edge: .top))
            }
        }
    }
    
    private var canSubmit: Bool {
        !currentPassword.isEmpty &&
        !newPassword.isEmpty &&
        newPassword == confirmPassword &&
        newPassword.count >= 8
    }
}
