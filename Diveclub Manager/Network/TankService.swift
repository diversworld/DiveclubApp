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

    // passt zu deiner /api/tanks Ausgabe
    // APIClient.decoder.keyDecodingStrategy = .convertFromSnakeCase
    // => check_id wird automatisch zu checkId gemappt, wenn Property so heißt.
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

        // ✅ WICHTIG: check_id aus Backend
        let checkId: Int?
    }

    // POST /api/tanks
    struct CreateTankRequest: Encodable {
        let title: String
        let serialNumber: String
        let size: String
        let manufacturer: String?
        let bazNumber: String?
        let o2clean: Bool
        let status: String
        let checkId: Int?

        enum CodingKeys: String, CodingKey {
            case title, serialNumber, size, manufacturer, bazNumber, o2clean, status
            case checkId = "check_id"   // ✅ sicher (Backend nutzt check_id)
        }
    }

    // PATCH /api/tanks/{id}
    struct PatchTankRequest: Encodable {
        let title: String?
        let serialNumber: String?
        let size: String?
        let manufacturer: String?
        let bazNumber: String?
        let o2clean: Bool?

        // ✅ neu
        let status: String?
        let checkId: Int?

        enum CodingKeys: String, CodingKey {
            case title, serialNumber, size, manufacturer, bazNumber, o2clean, status
            case checkId = "check_id"   // ✅ sicher
        }
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
    /// - Beim Speichern im Backend:
    ///   - status = "owned" (Privateigentum)
    ///   - check_id = letzte TÜV-Prüfung (proposal.checkId)
    func upsertTank(
        serialNumber: String,
        title: String?,
        manufacturer: String?,
        bazNumber: String?,
        size: String,
        o2clean: Bool,
        checkId: Int?
    ) async throws -> TankDTO {

        let normalizedSN = normalizeSerial(serialNumber)

        let existing = try await loadMyTanks()
        if let found = existing.first(where: { normalizeSerial($0.serialNumber) == normalizedSN }) {

            // gewünschte Werte
            let desiredTitle =
                clean(title)
                ?? clean(found.title)
                ?? defaultTitle(for: serialNumber)

            let desiredManufacturer = clean(manufacturer) ?? ""
            let desiredBaz = clean(bazNumber) ?? ""
            let desiredSize = clean(size) ?? size
            let desiredO2 = o2clean
            let desiredStatus = "owned"
            let desiredCheckId = checkId

            // aktuelle Werte (trimmed)
            let curTitle = clean(found.title) ?? ""
            let curMan = clean(found.manufacturer) ?? ""
            let curBaz = clean(found.bazNumber) ?? ""
            let curSize = clean(found.size) ?? ""
            let curO2 = found.o2clean ?? false
            let curStatus = clean(found.status) ?? ""
            let curCheckId = found.checkId

            let needsTitle = desiredTitle != curTitle
            let needsMan = desiredManufacturer != curMan
            let needsBaz = desiredBaz != curBaz
            let needsSize = desiredSize != curSize
            let needsO2 = desiredO2 != curO2
            
            // ✅ status muss auf owned
            let needsStatus = desiredStatus != curStatus

            // ✅ check_id nur patchen wenn:
            // - desiredCheckId != nil UND (curCheckId != desiredCheckId)
            // (wenn proposal.checkId nil ist, patchen wir check_id nicht)
            let needsCheckId = (desiredCheckId != nil) && (curCheckId != desiredCheckId)

            // ✅ kein PATCH wenn nix geändert
            guard needsTitle || needsMan || needsBaz || needsSize || needsO2 || needsStatus || needsCheckId else {
                return found
            }

            let patch = PatchTankRequest(
                title: needsTitle ? desiredTitle : nil,
                serialNumber: nil, // SN bleibt stabil
                size: needsSize ? desiredSize : nil,
                manufacturer: needsMan ? (desiredManufacturer.isEmpty ? nil : desiredManufacturer) : nil,
                bazNumber: needsBaz ? (desiredBaz.isEmpty ? nil : desiredBaz) : nil,
                o2clean: needsO2 ? desiredO2 : nil,
                status: needsStatus ? desiredStatus : nil,
                checkId: needsCheckId ? desiredCheckId : nil
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
            o2clean: o2clean,
            status: "owned",          // ✅ Privateigentum
            checkId: checkId          // ✅ letzte Prüfung
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
        return noWS.replacingOccurrences(of: "/{2,}", with: "/", options: .regularExpression)
    }
}
