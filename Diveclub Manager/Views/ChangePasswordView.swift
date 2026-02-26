//
//  ChangePasswordView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import SwiftUI

struct ChangePasswordView: View {
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""

    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        List {
            Section("Aktuelles Passwort") {
                SecureField("Aktuelles Passwort", text: $currentPassword)
                    .textContentType(.password)
            }

            Section("Neues Passwort") {
                SecureField("Neues Passwort", text: $newPassword)
                    .textContentType(.newPassword)
                SecureField("Neues Passwort bestätigen", text: $confirmPassword)
                    .textContentType(.newPassword)
            }

            Section {
                Button {
                    Task { await changePassword() }
                } label: {
                    HStack {
                        if isSaving { ProgressView() }
                        Text("Passwort ändern")
                    }
                }
                .disabled(isSaving || currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty)
            }

            if let err = errorMessage {
                Section { Text(err).foregroundStyle(.red) }
            }
        }
        .navigationTitle("Passwort ändern")
        .alert("Erfolg", isPresented: Binding(
            get: { successMessage != nil },
            set: { _ in successMessage = nil }
        )) {
            Button("OK") {}
        } message: {
            Text(successMessage ?? "")
        }
    }

    private struct ChangePasswordPayload: Encodable {
        let currentPassword: String
        let newPassword: String
    }

    @MainActor
    private func changePassword() async {
        errorMessage = nil
        guard newPassword == confirmPassword else {
            errorMessage = "Neues Passwort stimmt nicht mit Bestätigung überein."
            return
        }
        guard newPassword.count >= 6 else {
            errorMessage = "Neues Passwort ist zu kurz (mind. 6 Zeichen)."
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let payload = ChangePasswordPayload(currentPassword: currentPassword, newPassword: newPassword)
            try await APIClient.shared.requestWithoutResponse("change-password", method: "POST", body: payload)

            currentPassword = ""
            newPassword = ""
            confirmPassword = ""
            successMessage = "Passwort wurde geändert."
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
