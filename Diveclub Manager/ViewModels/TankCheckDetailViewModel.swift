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

    private let tankStore = TankStore.shared

    struct DraftTankCheckItem: Identifiable, Equatable {
        let id = UUID()

        var serialNumber: String = ""
        var manufacturer: String = ""
        var bazNumber: String = ""
        var size: String = "12"      // Backend-size key (z.B. "12")
        var o2clean: Bool = false
        var notes: String = ""

        /// nur optionale Artikel (Default + Basis werden automatisch ergänzt)
        var selectedOptionalArticleIds: Set<Int> = []
    }

    // MARK: - Load

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
        } catch {
            errorMessage = describe(error)
            proposal = nil
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

    func optionalArticlesForUI() -> [TankCheckArticleDTO] {
        guard let proposal else { return [] }
        return proposal.articles
            .filter { !$0.isDefault }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    // MARK: - Basisartikel (Preis nach Flaschengröße)

    /// Mapping nach deiner Backend-Logik
    private func baseSizeBucket(forTankSize sizeKey: String) -> String {
        // sizeKey ist z.B. "2","8","10","12","15","11"(40cft),"22"(80cft)
        switch sizeKey {
        case "2", "3", "4", "5", "7", "8":
            return "8"
        case "10":
            return "10"
        default:
            // 12/15/18/20 + cft => "über 10L"
            return "80"
        }
    }

    private func baseArticleId(forTankSize sizeKey: String) -> Int? {
        guard let proposal else { return nil }
        let bucket = baseSizeBucket(forTankSize: sizeKey)

        // nimm Artikel mit articleSize == bucket und im Titel etwas nach "Volumen"/"Liter" aussieht
        let candidates = proposal.articles.filter { a in
            (a.articleSize ?? "") == bucket
                && a.title.lowercased().contains("volumen")
        }

        if let best = candidates.sorted(by: { $0.priceBruttoDecimal < $1.priceBruttoDecimal }).first {
            return best.id
        }

        // fallback: nur nach articleSize
        return proposal.articles.first(where: { ($0.articleSize ?? "") == bucket })?.id
    }

    // MARK: - Artikel je Item

    func articleIds(for item: DraftTankCheckItem) -> [Int] {
        var ids = Set<Int>()

        // Pflicht
        ids.formUnion(mandatoryArticleIds)

        // Basispreis automatisch
        if let base = baseArticleId(forTankSize: item.size) {
            ids.insert(base)
        }

        // optionale Auswahl
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

    // MARK: - Saved Tanks

    var savedTanks: [SavedTank] { tankStore.tanks }

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

        let tank = SavedTank(
            serialNumber: sn,
            manufacturer: item.manufacturer,
            bazNumber: item.bazNumber,
            size: item.size,
            o2clean: item.o2clean,
            ownerMemberId: AuthManager.shared.currentMemberIdInt
        )
        tankStore.addOrUpdate(tank)
    }

    // MARK: - Submit

    func submitBooking() async {
        guard let proposal else {
            bookingError = "TÜV-Angebot nicht geladen."
            return
        }
        guard !isSubmitting else { return }

        for (idx, it) in items.enumerated() {
            if it.serialNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                bookingError = "Bitte Seriennummer für Flasche \(idx + 1) eingeben."
                return
            }
        }
        
        #if DEBUG
        for (idx, it) in items.enumerated() {
            let ids = articleIds(for: it)
            print("🧾 Tank \(idx+1) size=\(it.size) -> articles=\(ids)")
        }
        print("🧾 totalPrice=\(totalPrice)")
        #endif
                
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

        let payload = TankCheckBookRequest(
            proposalId: proposal.id,
            notes: bookingNotes.isEmpty ? nil : bookingNotes,
            items: payloadItems
        )

        #if DEBUG
        for (idx, it) in items.enumerated() {
            print("🧾 Tank \(idx+1) size=\(it.size) -> articles=\(articleIds(for: it))")
        }
        #endif

        do {
            let response = try await APIClient.shared.bookTankCheck(payload)

            #if DEBUG
            print("⬅️ Response (dump):")
            dump(response)
            print("⬅️ success=\(response.success ?? false), id=\(String(describing: response.id))")
            #endif

            bookingSuccess = true
        } catch {
            #if DEBUG
            print("❌ Booking failed: \(error)")
            #endif
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
}

