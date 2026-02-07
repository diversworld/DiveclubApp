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
            
            // MARK: - Sicherheit
            
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
            
            // MARK: - Server
            
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
                
                Button("Speichern") {
                    saveURL()
                }
                .disabled(!settings.isValidURL(tempURL))
                
                Divider()
                
                // MARK: - Verbindung testen
                
                Button {
                    Task {
                        await testConnection()
                    }
                } label: {
                    HStack {
                        Text("Verbindung testen")
                        
                        Spacer()
                        
                        if isTesting {
                            ProgressView()
                        }
                        else if let result = testResult {
                            Image(systemName: result ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(result ? .green : .red)
                        }
                    }
                }
                .disabled(!settings.isValidURL(tempURL))
            }
        }
        .navigationTitle("Einstellungen")
        .onAppear {
            tempURL = settings.baseURL
        }
    }
    
    // MARK: - Save
    
    private func saveURL() {
        var url = tempURL.trimmingCharacters(in: .whitespaces)
        
        if !url.hasSuffix("/api") {
            url += "/api"
        }
        
        settings.updateBaseURL(url)
        tempURL = url
    }
    
    // MARK: - Test
    
    private func testConnection() async {
        
        testResult = nil
        isTesting = true
        
        let result = await APIClient.shared.testConnection(to: tempURL)
        
        await MainActor.run {
            testResult = result
            isTesting = false
        }
    }
}
