//
//  EquipmentRentalViewModel.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 10.02.26.
//

import Foundation
import Combine

@MainActor
final class EquipmentRentalViewModel: ObservableObject {

    // MARK: - Dates / Notes

    @Published var startDate: Date = Date()
    @Published var endDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()

    @Published var reservedFor: String = ""   // optional member id
    @Published var defaultNotes: String = ""

    // MARK: - UI State

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    // MARK: - Assets

    @Published var selectedCategory: Category = .equipment
    @Published private(set) var allAssets: [EquipmentAsset] = []

    // Selected set uses asset.uniqueKey
    @Published var selected: Set<String> = []

    // MARK: - Options for subtype mapping

    @Published private(set) var equipmentOptions: EquipmentOptionsDTO?

    // MARK: - Per-item meta

    struct ItemMeta: Equatable {
        var notes: String = ""
        var types: String? = nil     // "1", "2", ...
        var subType: String? = nil   // "1", "2", ...
    }

    @Published private var metaByKey: [String: ItemMeta] = [:]

    // MARK: - Category

    enum Category: String, CaseIterable, Identifiable {
        case equipment, tank, regulator
        var id: String { rawValue }
    }

    // MARK: - Derived

    var visibleAssets: [EquipmentAsset] {
        allAssets.filter { $0.type.rawValue == selectedCategory.rawValue }
    }

    // MARK: - Selection helpers

    func isSelected(_ asset: EquipmentAsset) -> Bool {
        selected.contains(asset.uniqueKey)
    }

    func toggleSelection(_ asset: EquipmentAsset) {
        let key = asset.uniqueKey
        if selected.contains(key) {
            selected.remove(key)
        } else {
            selected.insert(key)
            if metaByKey[key] == nil {
                metaByKey[key] = ItemMeta(notes: defaultNotes, types: nil, subType: nil)
            }
        }
    }

    func meta(for asset: EquipmentAsset) -> ItemMeta {
        metaByKey[asset.uniqueKey] ?? ItemMeta(notes: defaultNotes, types: nil, subType: nil)
    }

    func updateMeta(for asset: EquipmentAsset, _ meta: ItemMeta) {
        metaByKey[asset.uniqueKey] = meta
    }

    // Falls du echte Availability hast, lass deine Logik stehen.
    func isAvailable(_ asset: EquipmentAsset) -> Bool { true }

    // MARK: - Loading

    func loadAssets() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await loadEquipmentOptionsIfNeeded()

            // ⚠️ HIER: nutze deinen echten Endpoint (ich kenne ihn nicht)
            // Beispiel:
            // allAssets = try await APIClient.shared.request("equipment/assets")
            allAssets = try await APIClient.shared.request("equipment/assets")

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadEquipmentOptionsIfNeeded() async throws {
        if equipmentOptions != nil { return }
        let opts: EquipmentOptionsDTO = try await APIClient.shared.request("equipment/options")
        equipmentOptions = opts
    }

    // MARK: - Reservation (✅ sends sub_type)

    func createReservation() async {
        guard !isLoading else { return }
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

        // Items bauen (✅ includes types + sub_type)
        let items: [EquipmentReservationRequest.Item] = selected.compactMap { key in
            guard let asset = allAssets.first(where: { $0.uniqueKey == key }) else { return nil }
            let meta = metaByKey[key] ?? ItemMeta(notes: defaultNotes)

            return EquipmentReservationRequest.Item(
                assetType: asset.type.backendItemType,
                assetId: asset.id,
                quantity: 1,
                types: meta.types,
                subType: meta.subType,
                notes: meta.notes.isEmpty ? nil : meta.notes
            )
        }

        guard !items.isEmpty else {
            errorMessage = "Bitte mindestens einen Gegenstand auswählen."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let payload = EquipmentReservationRequest(
                memberId: memberId,
                reservedFor: .init(start: startTs, end: endTs),
                assetType: selectedCategory.rawValue,
                items: items,
                notes: defaultNotes.isEmpty ? nil : defaultNotes
            )

            let _: EquipmentReservation = try await APIClient.shared.request(
                "reservations",
                method: "POST",
                body: payload
            )

            successMessage = "Reservierung wurde angelegt."
            selected.removeAll()

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Category helper

    func goToNextCategory() {
        let all = Category.allCases
        guard let idx = all.firstIndex(of: selectedCategory) else { return }
        selectedCategory = all[(idx + 1) % all.count]
    }
}
