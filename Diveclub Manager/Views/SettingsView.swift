//
//  SettingsView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import SwiftUI
import WebKit

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettingsManager

    @State private var tempURL: String = ""
    @State private var isTesting = false
    @State private var testResult: Bool? = nil
    @State private var testMessage: String? = nil
    
    // ✅ Feedback für "Übernehmen"
    @State private var didSave = false
    @State private var saveMessage: String? = nil

    var body: some View {
        Form {
            Section("Server") {
                TextField("Base URL", text: $tempURL)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .autocorrectionDisabled(true)

                Button {
                    applyBaseURL()
                } label: {
                    HStack {
                        Text("Übernehmen")
                        Spacer()
                        if didSave {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
                .disabled(!settings.isValidURL(tempURL))

                if let msg = saveMessage, !msg.isEmpty {
                    Text(msg)
                        .font(.body)
                        .foregroundStyle(.green)
                        .transition(.opacity)
                }

                Divider()

                Button {
                    Task { await runConnectionTest() }
                } label: {
                    HStack {
                        Text("Verbindung testen")
                        Spacer()

                        if isTesting {
                            ProgressView()
                        } else if let result = testResult {
                            Image(systemName: result ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(result ? .green : .red)
                        }
                    }
                }
                .disabled(!settings.isValidURL(tempURL) || isTesting)

                if let msg = testMessage, !msg.isEmpty {
                    Text(msg)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Rechtliches") {
                if settings.isLoadingConfig {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Lade Inhalte…")
                            .foregroundStyle(.secondary)
                    }
                } else if let err = settings.configError {
                    Text("Hinweis: \(err)")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                NavigationLink("Impressum") {
                    LegalHTMLView(title: "Impressum", html: settings.imprintHTML)
                }
                .disabled(settings.imprintHTML.isEmpty)

                NavigationLink("Datenschutz") {
                    LegalHTMLView(title: "Datenschutz", html: settings.privacyHTML)
                }
                .disabled(settings.privacyHTML.isEmpty)

                NavigationLink("Nutzungsbedingungen") {
                    LegalHTMLView(title: "Nutzungsbedingungen", html: settings.termsHTML)
                }
                .disabled(settings.termsHTML.isEmpty)
            }
            
            Section {
                HStack {
                    Text("App-Version")
                    Spacer()
                    Text(settings.appVersionString)
                        .foregroundStyle(.secondary)
                }
            }
            // Rechtliches aktuell NICHT in AppSettingsManager vorhanden.
            // Entweder hier entfernen oder AppSettingsManager um Texte ergänzen.
        }
        .navigationTitle("Einstellungen")
        .onAppear {
            tempURL = settings.baseURL
            Task { await settings.reloadRemoteConfig() }
        }
    }

    // MARK: - Save

        private func applyBaseURL() {
            let trimmed = tempURL.trimmingCharacters(in: .whitespacesAndNewlines)

            guard settings.isValidURL(trimmed) else {
                withAnimation {
                    didSave = false
                    saveMessage = "Bitte eine gültige https-URL eingeben."
                }
                return
            }

            settings.updateBaseURL(trimmed)

            // Erfolg anzeigen
            withAnimation {
                didSave = true
                saveMessage = "Gespeichert ✅"
            }

            // Ergebnis vom Verbindungstest zurücksetzen (weil neue URL)
            testResult = nil
            testMessage = nil

            // nach kurzer Zeit ausblenden
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                withAnimation {
                    didSave = false
                    saveMessage = nil
                }
            }
        }
    
    // MARK: - Connection Test
    
    private func runConnectionTest() async {
        guard settings.isValidURL(tempURL) else { return }

        isTesting = true
        testResult = nil
        testMessage = nil
        defer { isTesting = false }

        do {
            let ok = try await APIClient.shared.testConnection(baseURLString: tempURL)
            testResult = ok
            testMessage = ok ? "Verbindung erfolgreich." : "Keine Verbindung möglich."
        } catch {
            testResult = false
            testMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
