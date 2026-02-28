//
//  TankService.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 28.02.26.
//

import Foundation

@MainActor
final class TankService {
    static let shared = TankService()
    private init() {}

    // passt zu deiner /api/tanks Ausgabe (o2clean ist camelCase)
    struct TankDTO: Decodable, Identifiable, Equatable {
        let id: Int
        let title: String?
        let serialNumber: String?
        let manufacturer: String?
        let bazNumber: String?
        let size: String?
        let o2clean: Bool?

        // optional
        let owner: Int?
        let status: String?
        let rentalFee: String?
        let lastCheckDate: Int?
        let nextCheckDate: Int?
        let notes: String?
    }

    struct CreateTankRequest: Encodable {
        let title: String
        let serialNumber: String
        let size: String
        let manufacturer: String?
        let bazNumber: String?
        let o2clean: Bool
    }

    struct PatchTankRequest: Encodable {
        let title: String?
        let serialNumber: String?
        let size: String?
        let manufacturer: String?
        let bazNumber: String?
        let o2clean: Bool?
    }

    // MARK: - API

    func loadMyTanks() async throws -> [TankDTO] {
        try await APIClient.shared.request("tanks")
    }

    func createTank(_ req: CreateTankRequest) async throws -> TankDTO {
        try await APIClient.shared.request("tanks", method: "POST", body: req)
    }

    func patchTank(id: Int, _ req: PatchTankRequest) async throws -> TankDTO {
        try await APIClient.shared.request("tanks/\(id)", method: "PATCH", body: req)
    }

    func deleteTank(id: Int) async throws {
        try await APIClient.shared.requestWithoutResponse("tanks/\(id)", method: "DELETE", body: Optional<String>.none)
    }

    // MARK: - Upsert with duplicate check + diff patch

    /// - Duplikat: serialNumber normalisiert vergleichen
    /// - PATCH nur wenn sich Felder unterscheiden, sonst return found
    func upsertTank(
        serialNumber: String,
        title: String?,
        manufacturer: String?,
        bazNumber: String?,
        size: String,
        o2clean: Bool
    ) async throws -> TankDTO {

        let normalizedSN = normalizeSerial(serialNumber)

        let existing = try await loadMyTanks()
        if let found = existing.first(where: { normalizeSerial($0.serialNumber) == normalizedSN }) {

            // gewünschte Werte
            let desiredTitle =
                clean(title)
                ?? clean(found.title)
                ?? defaultTitle(for: serialNumber)

            let desiredManufacturer = clean(manufacturer)
            let desiredBaz = clean(bazNumber)
            let desiredSize = clean(size) ?? size

            // aktuelle Werte (trimmed)
            let curTitle = clean(found.title) ?? ""
            let curMan = clean(found.manufacturer) ?? ""
            let curBaz = clean(found.bazNumber) ?? ""
            let curSize = clean(found.size) ?? ""
            let curO2 = found.o2clean ?? false

            let needsTitle = desiredTitle != curTitle
            let needsMan = (desiredManufacturer ?? "") != curMan
            let needsBaz = (desiredBaz ?? "") != curBaz
            let needsSize = desiredSize != curSize
            let needsO2 = o2clean != curO2

            // ✅ kein PATCH wenn nix geändert
            guard needsTitle || needsMan || needsBaz || needsSize || needsO2 else {
                return found
            }

            let patch = PatchTankRequest(
                title: needsTitle ? desiredTitle : nil,
                serialNumber: nil, // SN bleibt i.d.R. stabil; optional patchen wenn du willst
                size: needsSize ? desiredSize : nil,
                manufacturer: needsMan ? desiredManufacturer : nil,
                bazNumber: needsBaz ? desiredBaz : nil,
                o2clean: needsO2 ? o2clean : nil
            )

            return try await patchTank(id: found.id, patch)
        }

        // POST
        let post = CreateTankRequest(
            title: clean(title) ?? defaultTitle(for: serialNumber),
            serialNumber: serialNumber,
            size: clean(size) ?? size,
            manufacturer: clean(manufacturer),
            bazNumber: clean(bazNumber),
            o2clean: o2clean
        )
        return try await createTank(post)
    }

    // MARK: - Helpers

    /// trimmt und wandelt "" -> nil
    private func clean(_ s: String?) -> String? {
        guard let s else { return nil }
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }

    private func defaultTitle(for serial: String) -> String {
        let sn = serial.trimmingCharacters(in: .whitespacesAndNewlines)
        return sn.isEmpty ? "Flasche" : "Flasche \(sn)"
    }

    /// Normalisierung für Duplikat-Check
    private func normalizeSerial(_ s: String?) -> String {
        let raw = (s ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let noWS = raw.replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
        let collapsed = noWS.replacingOccurrences(of: "/{2,}", with: "/", options: .regularExpression)
        return collapsed
    }
}
