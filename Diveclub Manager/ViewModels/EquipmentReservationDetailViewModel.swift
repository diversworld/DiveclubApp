//
//  EquipmentReservationDetailViewModel.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 10.02.26.
//

import Foundation
import Combine

@MainActor
final class EquipmentReservationDetailViewModel: ObservableObject {

    let reservationId: Int

    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var detail: ReservationDetailDTO? = nil

    // Lookups für Item-Details
    @Published var tanksById: [Int: TankDTO] = [:]
    @Published var regsById: [Int: RegulatorDTO] = [:]
    @Published var eqById: [Int: EquipmentDTO] = [:]

    // Options
    @Published var equipmentOptions: EquipmentOptionsDTO? = nil
    @Published var sizesOptions: SizesOptionsDTO? = nil
    @Published var regulatorOptions: RegulatorOptionsDTO? = nil

    init(reservationId: Int) {
        self.reservationId = reservationId
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // ✅ APIClient hat bei dir: getReservation(id:) ODER du kannst request("reservations/{id}") benutzen.
            // Ich verwende request direkt, damit es überall passt.
            let d: ReservationDetailDTO = try await APIClient.shared.request("reservations/\(reservationId)")
            self.detail = d

            let items = d.items ?? []

            // Items-IDs sammeln (Backend-Tabellen-Namen aus deinen bisherigen Filtern)
            let tankIds: Set<Int> = Set(items
                .filter { $0.itemType == "tl_dc_tanks" }
                .compactMap { $0.itemId })

            let regIds: Set<Int> = Set(items
                .filter { $0.itemType == "tl_dc_regulators" }
                .compactMap { $0.itemId })

            let eqIds: Set<Int> = Set(items
                .filter { $0.itemType == "tl_dc_equipment" }
                .compactMap { $0.itemId })

            // ✅ Swift 6 Fix: KEIN async let hier, weil child tasks nonisolated sind
            // und deine DTOs evtl. (versehentlich) MainActor-isoliert sind.
            let allTanks: [TankDTO] = try await APIClient.shared.request("tanks")
            let allRegs: [RegulatorDTO] = try await APIClient.shared.request("regulators")
            let allEq: [EquipmentDTO] = try await APIClient.shared.request("equipment")

            let eqOpts: EquipmentOptionsDTO = try await APIClient.shared.request("equipment/options")
            let sizesOpts: SizesOptionsDTO = try await APIClient.shared.request("sizes/options")
            let regOpts: RegulatorOptionsDTO = try await APIClient.shared.request("regulator/options")

            self.equipmentOptions = eqOpts
            self.sizesOptions = sizesOpts
            self.regulatorOptions = regOpts

            // Dictionaries bauen (nur was wir brauchen)
            self.tanksById = Dictionary(uniqueKeysWithValues: allTanks
                .filter { tankIds.contains($0.id) }
                .map { ($0.id, $0) })

            self.regsById = Dictionary(uniqueKeysWithValues: allRegs
                .filter { regIds.contains($0.id) }
                .map { ($0.id, $0) })

            self.eqById = Dictionary(uniqueKeysWithValues: allEq
                .filter { eqIds.contains($0.id) }
                .map { ($0.id, $0) })

        } catch {
            self.detail = nil
            self.tanksById = [:]
            self.regsById = [:]
            self.eqById = [:]
            self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    // MARK: - Helpers (Labels)

    func equipmentTypeLabel(for typeKey: String?) -> String? {
        guard let k = typeKey, let opts = equipmentOptions?.types[k] else { return nil }
        return opts.name
    }

    func equipmentSubTypeLabel(typeKey: String?, subKey: String?) -> String? {
        guard let t = typeKey, let s = subKey, let type = equipmentOptions?.types[t] else { return nil }
        return type.subtypes[s]
    }

    func equipmentSizeLabel(_ size: Int?) -> String? {
        guard let size else { return nil }
        if let v = sizesOptions?.sizes[String(size)] { return v }
        if let v = equipmentOptions?.sizes[String(size)] { return v }
        return nil
    }

    func regulatorManufacturerLabel(_ manId: String?) -> String? {
        guard let id = manId, !id.isEmpty else { return nil }
        return regulatorOptions?.manufacturers[id] ?? id
    }

    func regulatorModel1Label(manufacturerId: String?, key: String?) -> String? {
        guard let m = manufacturerId, !m.isEmpty, let k = key, !k.isEmpty else { return nil }
        return regulatorOptions?.regulators[m]?.regModel1st[k] ?? k
    }

    func regulatorModel2Label(manufacturerId: String?, key: String?) -> String? {
        guard let m = manufacturerId, !m.isEmpty, let k = key, !k.isEmpty else { return nil }
        return regulatorOptions?.regulators[m]?.regModel2nd[k] ?? k
    }
}
