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

    @Published var assets: [EquipmentAsset] = []
    @Published var selected: Set<String> = []   // "type:id"
    @Published var reservedFor: String = ""     // optional Eingabe
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

            return CreateReservationItem(itemId: id, itemType: type.backendItemType)
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let payload = CreateReservationRequest(
                reservedFor: reservedForId,   // optional, Backend defaultet sonst auf userId
                eventId: 0,                   // optional (bei dir Default 0)
                assetType: "multiple",         // optional (bei dir Default 'multiple')
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
