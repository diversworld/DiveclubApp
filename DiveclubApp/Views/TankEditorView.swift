//
//  TankEditorView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 09.02.26.
//

import SwiftUI

struct TankEditorView: View {
    enum Mode { case create }

    let mode: Mode
    let onSave: (ScubaTank) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var nickname: String = ""
    @State private var serialNumber: String = ""
    @State private var volumeLiters: Int = 12
    @State private var workingPressureBar: Int = 200
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("Flasche") {
                TextField("Bezeichnung", text: $nickname)
                TextField("Seriennummer", text: $serialNumber)
                    .textInputAutocapitalization(.characters)

                Stepper("Volumen: \(volumeLiters)L", value: $volumeLiters, in: 1...30)
                Stepper("Arbeitsdruck: \(workingPressureBar) bar", value: $workingPressureBar, in: 100...300, step: 10)
            }

            if let errorMessage {
                Section { Text(errorMessage).foregroundStyle(.red) }
            }
        }
        .navigationTitle("Flasche hinzufügen")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Speichern") { save() }.fontWeight(.semibold)
            }
        }
    }

    private func save() {
        errorMessage = nil
        let nick = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let sn = serialNumber.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !nick.isEmpty else { errorMessage = "Bitte Bezeichnung eingeben."; return }
        guard !sn.isEmpty else { errorMessage = "Bitte Seriennummer eingeben."; return }

        let tank = ScubaTank(
            nickname: nick,
            serialNumber: sn,
            volumeLiters: volumeLiters,
            workingPressureBar: workingPressureBar
        )

        onSave(tank)
        dismiss()
    }
}
