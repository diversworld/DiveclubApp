//
//  TankCheckDetailViewModel.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 09.02.26.
//

import Foundation
import Combine

@MainActor
final class TankCheckDetailViewModel: ObservableObject {

    @Published var proposal: TankCheckProposalDetailDTO?
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var bookingNotes: String = ""
    @Published var items: [DraftTankCheckItem] = []

    @Published var isSubmitting = false
    @Published var bookingSuccess = false
    @Published var bookingError: String?

    // ✅ neu
    @Published var saveTanksToBackend: Bool = true
    @Published private(set) var savedTanks: [SavedTank] = []
    @Published var tanksError: String?

    struct DraftTankCheckItem: Identifiable, Equatable {
        let id = UUID()

        var serialNumber: String = ""
        var manufacturer: String = ""
        var bazNumber: String = ""
        var size: String = "12"
        var o2clean: Bool = false
        var notes: String = ""
        var selectedOptionalArticleIds: Set<Int> = []
    }

    // MARK: - Saved Tanks UI Model

    struct SavedTank: Identifiable, Equatable, Codable {
        let id: Int
        var title: String
        var serialNumber: String
        var manufacturer: String
        var bazNumber: String
        var size: String
        var o2clean: Bool

        var displayLine: String { "\(serialNumber) • \(Self.sizeLabel(size))" }

        static func sizeLabel(_ key: String) -> String {
            let map: [String: String] = [
                "2":"2 L","3":"3 L","4":"4 L","5":"5 L","7":"7 L","8":"8 L","10":"10 L",
                "12":"12 L","15":"15 L","18":"18 L","20":"20 L","11":"40 cft","22":"80 cft"
            ]
            return map[key] ?? key
        }
    }

    // MARK: - Local Storage (fallback)

    private let localKey = "saved_tanks_local_v1"

    private func loadLocalTanks() -> [SavedTank] {
        guard let data = UserDefaults.standard.data(forKey: localKey) else { return [] }
        return (try? JSONDecoder().decode([SavedTank].self, from: data)) ?? []
    }

    private func saveLocalTanks(_ tanks: [SavedTank]) {
        if let data = try? JSONEncoder().encode(tanks) {
            UserDefaults.standard.set(data, forKey: localKey)
        }
    }

    // MARK: - Load proposal

    func loadProposal(id: Int) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let detail: TankCheckProposalDetailDTO = try await APIClient.shared.getTankCheckProposal(id: id)
            proposal = detail

            if items.isEmpty {
                items = [DraftTankCheckItem()]
            }

            await loadSavedTanks()

        } catch {
            errorMessage = describe(error)
            proposal = nil
        }
    }

    // MARK: - Saved tanks load / apply / save / delete

    func loadSavedTanks() async {
        tanksError = nil

        if saveTanksToBackend {
            do {
                let api = try await TankService.shared.loadMyTanks()
                self.savedTanks = api.compactMap { dto in
                    let sn = (dto.serialNumber ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !sn.isEmpty else { return nil }
                    return SavedTank(
                        id: dto.id,
                        title: (dto.title ?? "").isEmpty ? "Flasche \(sn)" : (dto.title ?? ""),
                        serialNumber: sn,
                        manufacturer: dto.manufacturer ?? "",
                        bazNumber: dto.bazNumber ?? "",
                        size: dto.size ?? "12",
                        o2clean: dto.o2clean ?? false
                    )
                }
                .sorted { $0.serialNumber.localizedCaseInsensitiveCompare($1.serialNumber) == .orderedAscending }
            } catch {
                tanksError = describe(error)
                self.savedTanks = loadLocalTanks().sorted { $0.serialNumber.localizedCaseInsensitiveCompare($1.serialNumber) == .orderedAscending }
            }
        } else {
            self.savedTanks = loadLocalTanks().sorted { $0.serialNumber.localizedCaseInsensitiveCompare($1.serialNumber) == .orderedAscending }
        }
    }

    func applySavedTank(_ saved: SavedTank, to index: Int) {
        guard items.indices.contains(index) else { return }

        items[index].serialNumber = saved.serialNumber
        items[index].manufacturer = saved.manufacturer
        items[index].bazNumber = saved.bazNumber
        items[index].size = saved.size
        items[index].o2clean = saved.o2clean
    }

    func saveItemAsTank(_ item: DraftTankCheckItem) {
        let sn = item.serialNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sn.isEmpty else { return }

        if saveTanksToBackend {
            Task {
                do {
                    _ = try await TankService.shared.upsertTank(
                        serialNumber: sn,
                        title: nil,
                        manufacturer: item.manufacturer,
                        bazNumber: item.bazNumber,
                        size: item.size,
                        o2clean: item.o2clean
                    )
                    await loadSavedTanks()
                } catch {
                    tanksError = describe(error)
                }
            }
        } else {
            var local = loadLocalTanks()

            let norm = normalizeSerial(sn)
            if let idx = local.firstIndex(where: { normalizeSerial($0.serialNumber) == norm }) {
                local[idx].serialNumber = sn
                local[idx].manufacturer = item.manufacturer
                local[idx].bazNumber = item.bazNumber
                local[idx].size = item.size
                local[idx].o2clean = item.o2clean
            } else {
                let newId = -Int(Date().timeIntervalSince1970)
                local.append(
                    SavedTank(
                        id: newId,
                        title: "Flasche \(sn)",
                        serialNumber: sn,
                        manufacturer: item.manufacturer,
                        bazNumber: item.bazNumber,
                        size: item.size,
                        o2clean: item.o2clean
                    )
                )
            }

            saveLocalTanks(local)
            Task { await loadSavedTanks() }
        }
    }

    func deleteSavedTank(_ tank: SavedTank) {
        if saveTanksToBackend, tank.id > 0 {
            Task {
                do {
                    try await TankService.shared.deleteTank(id: tank.id)
                    await loadSavedTanks()
                } catch {
                    tanksError = describe(error)
                }
            }
        } else {
            var local = loadLocalTanks()
            local.removeAll { $0.id == tank.id }
            saveLocalTanks(local)
            Task { await loadSavedTanks() }
        }
    }

    // MARK: - Pflichtartikel

    private var mandatoryArticleIds: Set<Int> {
        guard let proposal else { return [] }
        return Set(proposal.articles.filter { $0.isDefault }.map { $0.id })
    }

    func defaultArticlesForUI() -> [TankCheckArticleDTO] {
        guard let proposal else { return [] }
        return proposal.articles
            .filter { $0.isDefault }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    // MARK: - Basisartikel

    private func baseSizeBucket(forTankSize sizeKey: String) -> String {
        switch sizeKey {
        case "2", "3", "4", "5", "7", "8": return "8"
        case "10": return "10"
        default: return "80"
        }
    }

    private func baseArticleId(forTankSize sizeKey: String) -> Int? {
        guard let proposal else { return nil }
        let bucket = baseSizeBucket(forTankSize: sizeKey)

        let candidates = proposal.articles.filter { a in
            (a.articleSize ?? "") == bucket && a.title.lowercased().contains("volumen")
        }
        if let best = candidates.sorted(by: { $0.priceBruttoDecimal < $1.priceBruttoDecimal }).first {
            return best.id
        }
        return proposal.articles.first(where: { ($0.articleSize ?? "") == bucket })?.id
    }

    private var allBaseArticleIds: Set<Int> {
        guard proposal != nil else { return [] }
        let representative = ["8", "10", "12"]
        return Set(representative.compactMap { baseArticleId(forTankSize: $0) })
    }

    func optionalArticlesForUI() -> [TankCheckArticleDTO] {
        guard let proposal else { return [] }
        return proposal.articles
            .filter { !$0.isDefault }
            .filter { a in
                if allBaseArticleIds.contains(a.id) { return false }
                if let s = a.articleSize, !s.isEmpty, a.title.lowercased().contains("volumen") { return false }
                return true
            }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    // MARK: - Artikel je Item

    func articleIds(for item: DraftTankCheckItem) -> [Int] {
        var ids = Set<Int>()
        ids.formUnion(mandatoryArticleIds)

        if let base = baseArticleId(forTankSize: item.size) {
            ids.insert(base)
        }

        ids.formUnion(item.selectedOptionalArticleIds)
        return Array(ids).sorted()
    }

    // MARK: - Preis

    func priceForItem(_ item: DraftTankCheckItem) -> Decimal {
        guard let proposal else { return 0 }
        let ids = Set(articleIds(for: item))
        return proposal.articles
            .filter { ids.contains($0.id) }
            .reduce(Decimal(0)) { $0 + $1.priceBruttoDecimal }
    }

    var totalPrice: Decimal {
        items.reduce(Decimal(0)) { $0 + priceForItem($1) }
    }

    // MARK: - Submit

    func submitBooking() async {
        guard let proposal else {
            bookingError = "TÜV-Angebot nicht geladen."
            return
        }
        guard !isSubmitting else { return }

        // ✅ checkId muss vorhanden sein, sonst kann Backend den Termin nicht zuordnen
        guard let checkId = proposal.checkId else {
            bookingError = "Prüfungstermin-ID (check_id) fehlt im Angebot. Bitte API prüfen (/api/tank-checks/{id})."
            return
        }

        for (idx, it) in items.enumerated() {
            if it.serialNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                bookingError = "Bitte Seriennummer für Flasche \(idx + 1) eingeben."
                return
            }
        }

        isSubmitting = true
        bookingError = nil
        bookingSuccess = false
        defer { isSubmitting = false }

        let payloadItems: [TankCheckBookItemRequest] = items.map { it in
            TankCheckBookItemRequest(
                serialNumber: it.serialNumber,
                manufacturer: it.manufacturer.isEmpty ? nil : it.manufacturer,
                bazNumber: it.bazNumber.isEmpty ? nil : it.bazNumber,
                size: it.size,
                price: (priceForItem(it) as NSDecimalNumber).doubleValue,
                o2clean: it.o2clean,
                articles: articleIds(for: it),
                notes: it.notes.isEmpty ? nil : it.notes
            )
        }

        // ✅ checkId mitgeben
        let payload = TankCheckBookRequest(
            proposalId: proposal.id,
            checkId: checkId,
            notes: bookingNotes.isEmpty ? nil : bookingNotes,
            items: payloadItems
        )

        do {
            _ = try await APIClient.shared.bookTankCheck(payload)
            bookingSuccess = true
        } catch {
            bookingError = describe(error)
        }
    }

    // MARK: - Helpers

    private func describe(_ error: Error) -> String {
        if case APIError.badStatus(let code, let body) = error {
            return "Serverfehler \(code): \(body ?? "")"
        }
        return (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }

    private func normalizeSerial(_ s: String) -> String {
        let raw = s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let noWS = raw.replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
        return noWS.replacingOccurrences(of: "/{2,}", with: "/", options: .regularExpression)
    }
}
