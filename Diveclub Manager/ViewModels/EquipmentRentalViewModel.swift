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

    struct ItemMeta: Equatable {
        var types: [Int] = []
        var subType: Int? = nil
        var notes: String = ""
    }

    @Published var assets: [EquipmentAsset] = []
    @Published var selected: Set<String> = []   // "type:id"
    @Published var reservedFor: String = ""     // optional Eingabe

    // Zusätzliche Felder für Items
    @Published var defaultTypes: [Int] = []
    @Published var defaultSubType: Int? = nil
    @Published var defaultNotes: String = ""

    // Per-Item Metadaten (überschreiben Defaults)
    @Published var perItemMeta: [String: ItemMeta] = [:]

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    // Zeitraum (UI)
    @Published var startDate: Date = .now
    @Published var endDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now

    func loadAssets() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // Diese DTOs müssen bei dir existieren und Decodable sein:
            let eq: [EquipmentDTO] = try await APIClient.shared.request("equipment")
            let tanks: [TankDTO] = try await APIClient.shared.request("tanks")
            let regs: [RegulatorDTO] = try await APIClient.shared.request("regulators")

            let mapped =
                eq.map { $0.toAsset() } +
                tanks.map { $0.toAsset() } +
                regs.map { $0.toAsset() }

            // MVP-Verfügbarkeit: status == "available"
            assets = mapped.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        } catch {
            errorMessage = error.localizedDescription
            assets = []
        }
    }

    func toggleSelection(_ asset: EquipmentAsset) {
        let key = "\(asset.type.rawValue):\(asset.id)"
        if selected.contains(key) { selected.remove(key) } else { selected.insert(key) }
    }

    func isSelected(_ asset: EquipmentAsset) -> Bool {
        selected.contains("\(asset.type.rawValue):\(asset.id)")
    }

    func meta(for asset: EquipmentAsset) -> ItemMeta {
        let key = "\(asset.type.rawValue):\(asset.id)"
        return perItemMeta[key] ?? ItemMeta()
    }

    func updateMeta(for asset: EquipmentAsset, _ meta: ItemMeta) {
        let key = "\(asset.type.rawValue):\(asset.id)"
        perItemMeta[key] = meta
    }

    func createReservation() async {
        successMessage = nil
        errorMessage = nil

        guard !selected.isEmpty else {
            errorMessage = "Bitte mindestens einen Gegenstand auswählen."
            return
        }

        // reservedFor optional
        let reservedForId: Int? = {
            let trimmed = reservedFor.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            return Int(trimmed)
        }()

        // Items bauen
        let items: [CreateReservationItem] = selected.compactMap { key in
            // key = "type:id"
            let parts = key.split(separator: ":")
            guard parts.count == 2,
                  let type = EquipmentAssetType(rawValue: String(parts[0])),
                  let id = Int(parts[1]) else { return nil }

            let keyStr = "\(type.rawValue):\(id)"
            let meta = perItemMeta[keyStr] ?? ItemMeta(types: defaultTypes, subType: defaultSubType, notes: defaultNotes)
            return CreateReservationItem(
                itemId: id,
                itemType: type.backendItemType,
                types: meta.types.isEmpty ? nil : meta.types,
                subType: meta.subType,
                notes: meta.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : meta.notes
            )
        }

        // Resolve memberId from session (fallback demo)
        if UserSession.shared.memberId == nil {
            // TODO: Entfernen, sobald echte Auth den memberId setzt
            UserSession.shared.memberId = 4
        }
        guard let memberId = UserSession.shared.memberId else {
            errorMessage = "Kein Mitglied angemeldet (memberId fehlt)."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let payload = CreateReservationRequest(
                memberId: memberId,
                reservedFor: reservedForId,
                eventId: 0,
                assetType: "multiple",
                items: items
            )

            let resp = try await APIClient.shared.createReservation(payload)

            if resp.success, let id = resp.id {
                successMessage = "Reservierung angelegt (#\(id))."
                selected.removeAll()
            } else {
                errorMessage = "Reservierung konnte nicht angelegt werden."
            }

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // Helfer für MVP: verfügbar?
    func isAvailable(_ asset: EquipmentAsset) -> Bool {
        (asset.status ?? "").lowercased() == "available"
    }
}

