//
//  ChangePasswordView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

//
//  ChangePasswordView.swift
//  DiveclubApp
//

import SwiftUI

struct ChangePasswordView: View {

    @ObservedObject var vm: ProfileViewModel

    @Environment(\.dismiss) private var dismiss

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""

    private var canSave: Bool {
        !currentPassword.isEmpty &&
        !newPassword.isEmpty &&
        newPassword == confirmPassword &&
        newPassword.count >= 8 &&
        !vm.isSaving
    }

    var body: some View {
        Form {
            Section("Aktuelles Passwort") {
                SecureField("Aktuelles Passwort", text: $currentPassword)
            }

            Section("Neues Passwort") {
                SecureField("Neues Passwort", text: $newPassword)
                SecureField("Neues Passwort bestätigen", text: $confirmPassword)

                if !confirmPassword.isEmpty && newPassword != confirmPassword {
                    Text("Passwörter stimmen nicht überein.")
                        .foregroundStyle(.red)
                        .font(.footnote)
                }

                Text("Mindestens 8 Zeichen.")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            }

            if let error = vm.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
            }
        }
        .navigationTitle("Passwort ändern")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Abbrechen") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await vm.changePassword(
                            current: currentPassword,
                            new: newPassword
                        )
                        if vm.saveSuccess {
                            dismiss()
                        }
                    }
                } label: {
                    if vm.isSaving {
                        ProgressView()
                    } else {
                        Text("Speichern")
                    }
                }
                .disabled(!canSave)
            }
        }
    }
}
