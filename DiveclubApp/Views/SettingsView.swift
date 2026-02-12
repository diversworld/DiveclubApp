//
//  SettingsView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import SwiftUI

struct SettingsView: View {

    @StateObject private var settings = AppSettingsManager.shared

    @State private var tempURL: String = ""
    @State private var isTesting = false
    @State private var testResult: Bool?

    var body: some View {
        Form {

            Section("Sicherheit") {
                Stepper(
                    "Timeout: \(Int(settings.timeout)) Sekunden",
                    value: Binding(
                        get: { settings.timeout },
                        set: { settings.updateTimeout($0) }
                    ),
                    in: 30...600,
                    step: 30
                )
            }

            Section("Server") {
                TextField("API Base URL", text: $tempURL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)

                if !settings.isValidURL(tempURL) && !tempURL.isEmpty {
                    Text("Ungültige URL. Nur https ist erlaubt.")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button("Übernehmen") {
                    settings.updateBaseURL(tempURL)
                }
                .disabled(!settings.isValidURL(tempURL))
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
                                .foregroundColor(result ? .green : .red)
                        }
                    }
                }
                .disabled(!settings.isValidURL(tempURL) || isTesting)
            }
            .onAppear {
                tempURL = settings.baseURL
            }
                
            Section("Rechtliches") {
                NavigationLink("Impressum") { LegalTextView(title: "Impressum", text: AppLegal.imprint) }
                NavigationLink("Datenschutz") { LegalTextView(title: "Datenschutz", text: AppLegal.privacy) }
                NavigationLink("Nutzungsbedingungen") { LegalTextView(title: "Nutzungsbedingungen", text: AppLegal.terms) }
            }
        }
        .navigationTitle("Einstellungen")
        .onAppear {
            tempURL = settings.baseURL
        }
    }

    // MARK: - Save

    private func saveURL() {
        let url = tempURL.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.updateBaseURL(url)
        tempURL = url
    }

    // MARK: - Test

    private func runConnectionTest() async {
        testResult = nil
        isTesting = true
        defer { isTesting = false }

        let ok = await testConnection(to: tempURL)
        testResult = ok
    }

    /// Ping gegen `.../api/auth/me` (oder ändere den Pfad auf deinen Health-Endpoint)
    private func testConnection(to base: String) async -> Bool {
        do {
            var normalized = base.trimmingCharacters(in: .whitespacesAndNewlines)
            if !normalized.hasSuffix("/") { normalized += "/" }

            guard let baseURL = URL(string: normalized),
                  let url = URL(string: "api/me", relativeTo: baseURL) else { return false }

            var req = URLRequest(url: url)
            req.httpMethod = "GET"
            req.setValue("application/json", forHTTPHeaderField: "Accept")

            // Wenn auth/me Token braucht, wird es ohne Token 401 liefern.
            // Dann lieber /health oder /ping testen (public).
            // req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (_, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse else { return false }

            // 200...299 = Server erreichbar und OK
            return (200...299).contains(http.statusCode) || http.statusCode == 401
        } catch {
            #if DEBUG
            print("❌ testConnection(to:) failed:", error.localizedDescription)
            #endif
            return false
        }
    }
}
