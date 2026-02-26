//
//  EquipmentReservationCreateViewModel.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 10.02.26.
//

import Foundation
import Combine

@MainActor
final class EquipmentReservationCreateViewModel: ObservableObject {

    @Published var startDate: Date = Date()
    @Published var endDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()

    @Published var selected: Set<String> = [] // key = "\(type.rawValue)#\(id)"
    @Published var quantityByKey: [String: Int] = [:]

    @Published var isSubmitting = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    /// Optional: falls du globale Notes mitschicken willst
    @Published var notes: String = ""

    func toggle(asset: EquipmentAsset) {
        let key = Self.key(asset)
        if selected.contains(key) {
            selected.remove(key)
        } else {
            selected.insert(key)
            if quantityByKey[key] == nil { quantityByKey[key] = 1 }
        }
    }

    func quantity(for asset: EquipmentAsset) -> Int {
        quantityByKey[Self.key(asset)] ?? 1
    }

    func setQuantity(_ q: Int, for asset: EquipmentAsset) {
        let key = Self.key(asset)
        quantityByKey[key] = max(1, q)
        selected.insert(key)
    }

    func submit() async {
        guard !isSubmitting else { return }
        errorMessage = nil
        successMessage = nil

        guard endDate >= startDate else {
            errorMessage = "Enddatum muss nach dem Startdatum liegen."
            return
        }

        guard let memberId = AuthManager.shared.currentMember?.id else {
            errorMessage = "Kein Member-ID gefunden (bitte neu einloggen)."
            return
        }

        let startTs = Int(startDate.timeIntervalSince1970)
        let endTs = Int(endDate.timeIntervalSince1970)

        // Items bauen (✅ jetzt mit neuen Feldern)
        let items: [EquipmentReservationRequest.Item] = selected.compactMap { key -> EquipmentReservationRequest.Item? in
            let parts = key.split(separator: "#", maxSplits: 1).map(String.init)
            guard parts.count == 2, let assetId = Int(parts[1]) else { return nil }

            let type = parts[0]
            let qty = max(1, quantityByKey[key] ?? 1)

            return EquipmentReservationRequest.Item(
                assetType: type,
                assetId: assetId,
                quantity: qty,
                types: nil,
                subType: nil,
                notes: nil
            )
        }

        guard !items.isEmpty else {
            errorMessage = "Bitte mindestens einen Gegenstand auswählen."
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let payload = EquipmentReservationRequest(
                memberId: memberId,
                reservedFor: .init(start: startTs, end: endTs),
                assetType: "equipment",
                items: items,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes
            )

            let _: EquipmentReservation = try await APIClient.shared.request(
                "reservations",
                method: "POST",
                body: payload
            )

            successMessage = "Reservierung wurde angelegt."
            selected.removeAll()
            quantityByKey.removeAll()

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private static func key(_ asset: EquipmentAsset) -> String {
        "\(asset.type.rawValue)#\(asset.id)"
    }
}
