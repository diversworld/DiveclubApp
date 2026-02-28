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
            // Details
            let d: ReservationDetailDTO = try await APIClient.shared.request("reservations/\(reservationId)")
            self.detail = d

            let items = d.items ?? []

            // Items-IDs sammeln (Tabellennamen)
            let tankIds: Set<Int> = Set(items
                .filter { ($0.itemType ?? "").lowercased().contains("tank") }
                .compactMap { $0.itemId })

            let regIds: Set<Int> = Set(items
                .filter { ($0.itemType ?? "").lowercased().contains("regulator") }
                .compactMap { $0.itemId })

            let eqIds: Set<Int> = Set(items
                .filter { ($0.itemType ?? "").lowercased().contains("equipment") }
                .compactMap { $0.itemId })

            // Kataloge + Options laden (sequenziell -> Swift 6 safe)
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

    // MARK: - Equipment Labels (Options)

    func equipmentTypeLabel(for typeKey: String?) -> String? {
        guard let k = typeKey?.trimmingCharacters(in: .whitespacesAndNewlines), !k.isEmpty else { return nil }
        return equipmentOptions?.types[k]?.name
    }

    func equipmentSubTypeLabel(typeKey: String?, subKey: String?) -> String? {
        guard
            let t = typeKey?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty,
            let s = subKey?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty
        else { return nil }
        return equipmentOptions?.types[t]?.subtypes[s]
    }

    func equipmentManufacturerLabel(_ manufacturerId: String?) -> String? {
        guard let id = manufacturerId?.trimmingCharacters(in: .whitespacesAndNewlines), !id.isEmpty else { return nil }
        return equipmentOptions?.manufacturers[id] ?? manufacturerId
    }

    func equipmentSizeLabel(_ size: Int?) -> String? {
        guard let size else { return nil }
        let k = String(size)
        // bevorzugt sizes/options, fallback equipment/options
        if let v = sizesOptions?.sizes[k] { return v }
        if let v = equipmentOptions?.sizes[k] { return v }
        return nil
    }

    // MARK: - Regulator Labels (Options)

    func regulatorManufacturerLabel(_ manId: String?) -> String? {
        guard let id = manId?.trimmingCharacters(in: .whitespacesAndNewlines), !id.isEmpty else { return nil }
        return regulatorOptions?.manufacturers[id] ?? manId
    }

    func regulatorModel1Label(manufacturerId: String?, key: String?) -> String? {
        guard
            let m = manufacturerId?.trimmingCharacters(in: .whitespacesAndNewlines), !m.isEmpty,
            let k = key?.trimmingCharacters(in: .whitespacesAndNewlines), !k.isEmpty
        else { return nil }
        return regulatorOptions?.regulators[m]?.regModel1st[k] ?? k
    }

    func regulatorModel2Label(manufacturerId: String?, key: String?) -> String? {
        guard
            let m = manufacturerId?.trimmingCharacters(in: .whitespacesAndNewlines), !m.isEmpty,
            let k = key?.trimmingCharacters(in: .whitespacesAndNewlines), !k.isEmpty
        else { return nil }
        return regulatorOptions?.regulators[m]?.regModel2nd[k] ?? k
    }

    // MARK: - Pretty Strings for UI

    /// Anzeige: "Typ: Anzüge / halbtrocken"
    func prettyTypeLine(types: String?, subType: String?) -> String? {
        let t = equipmentTypeLabel(for: types)
        let st = equipmentSubTypeLabel(typeKey: types, subKey: subType)
        let joined = [t, st].compactMap { $0 }.joined(separator: " / ")
        return joined.isEmpty ? nil : "Typ: \(joined)"
    }

    /// Für Reservation-Items: Typ/Subtyp + Keys, wenn nicht auflösbar
    func prettyTypeLineWithFallback(types: String?, subType: String?) -> String? {
        if let pretty = prettyTypeLine(types: types, subType: subType) { return pretty }
        let t = (types?.isEmpty == false) ? "Typ-Key: \(types!)" : nil
        let st = (subType?.isEmpty == false) ? "Subtyp-Key: \(subType!)" : nil
        let joined = [t, st].compactMap { $0 }.joined(separator: " • ")
        return joined.isEmpty ? nil : joined
    }

    /// Equipment aus dem Katalog (EquipmentDTO) -> klarer Beschreibungstext
    func prettyEquipmentDetails(_ e: EquipmentDTO) -> [String] {
        var lines: [String] = []

        if let typeLine = prettyTypeLine(types: e.types, subType: e.sub_type) {
            lines.append(typeLine)
        }

        // Hersteller (Label vom Server bevorzugen, sonst Options)
        if let server = e.manufacturer_label, !server.isEmpty {
            lines.append("Hersteller: \(server)")
        } else if let man = equipmentManufacturerLabel(e.manufacturer) {
            lines.append("Hersteller: \(man)")
        }

        if let server = e.size_label, !server.isEmpty {
            lines.append("Größe: \(server)")
        } else if let sz = equipmentSizeLabel(e.size) {
            lines.append("Größe: \(sz)")
        }

        if let model = e.model, !model.isEmpty { lines.append("Modell: \(model)") }
        if let color = e.color, !color.isEmpty { lines.append("Farbe: \(color)") }

        return lines
    }

    /// Regler aus dem Katalog (RegulatorDTO) -> Modellnamen + Hersteller
    func prettyRegulatorDetails(_ r: RegulatorDTO) -> [String] {
        var lines: [String] = []

        if let man = regulatorManufacturerLabel(r.manufacturer) {
            lines.append("Hersteller: \(man)")
        }

        let m1  = regulatorModel1Label(manufacturerId: r.manufacturer, key: r.regModel1st)
        let m2p = regulatorModel2Label(manufacturerId: r.manufacturer, key: r.regModel2ndPri)
        let m2s = regulatorModel2Label(manufacturerId: r.manufacturer, key: r.regModel2ndSec)

        if let v = m1 { lines.append("1. Stufe: \(v)") }
        if let v = m2p { lines.append("2. Stufe (prim): \(v)") }
        if let v = m2s { lines.append("2. Stufe (sec): \(v)") }

        if let sn = r.serialNumber1st, !sn.isEmpty { lines.append("SN 1. Stufe: \(sn)") }
        if let sn = r.serialNumber2ndPri, !sn.isEmpty { lines.append("SN 2. Pri: \(sn)") }
        if let sn = r.serialNumber2ndSec, !sn.isEmpty { lines.append("SN 2. Sek: \(sn)") }

        return lines
    }
}
