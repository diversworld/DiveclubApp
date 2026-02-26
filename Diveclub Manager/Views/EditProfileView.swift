//
//  EditProfileView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 08.02.26.
//
import SwiftUI

struct EditProfileView: View {
    @State private var isLoading = false
    @State private var isSaving = false

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""

    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        List {
            Section("Profil") {
                TextField("Vorname", text: $firstName)
                    .textContentType(.givenName)
                TextField("Nachname", text: $lastName)
                    .textContentType(.familyName)
                TextField("E-Mail", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
            }

            Section {
                Button {
                    Task { await save() }
                } label: {
                    HStack {
                        if isSaving { ProgressView() }
                        Text("Speichern")
                    }
                }
                .disabled(isSaving || firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if let err = errorMessage {
                Section { Text(err).foregroundStyle(.red) }
            }
        }
        .navigationTitle("Profil bearbeiten")
        .task { await load() }
        .refreshable { await load() }
        .alert("Erfolg", isPresented: Binding(
            get: { successMessage != nil },
            set: { _ in successMessage = nil }
        )) {
            Button("OK") {}
        } message: {
            Text(successMessage ?? "")
        }
    }

    private struct MeDTO: Decodable {
        let firstName: String?
        let lastName: String?
        let email: String?
    }

    private struct SavePayload: Encodable {
        let firstName: String
        let lastName: String
        let email: String
    }

    @MainActor
    private func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let me: MeDTO = try await APIClient.shared.request("me", method: "GET")
            firstName = me.firstName ?? ""
            lastName = me.lastName ?? ""
            email = me.email ?? ""
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    @MainActor
    private func save() async {
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }

        do {
            let payload = SavePayload(
                firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
                lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
                email: email.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            try await APIClient.shared.requestWithoutResponse("me", method: "POST", body: payload)
            successMessage = "Profil gespeichert."
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
