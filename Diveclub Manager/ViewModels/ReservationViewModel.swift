import Foundation
import Combine

@MainActor
final class ReservationViewModel: ObservableObject {

    // MARK: - API DTOs / Items

    struct ItemDisplay {
        let title: String
        let subtitle: String?
        let groupTitle: String?
    }

    struct Draft: Identifiable {
        let id = UUID()
        let itemId: Int?
        let itemType: String
        let types: String?
        let subType: String?
        let notes: String?

        // ✅ neu: Anzeige-Infos, damit später nicht nur "#id • itemType" steht
        let displayTitle: String
        let displaySubtitle: String?
    }

    // MARK: - Options DTOs

    struct RegulatorOptionsDTO: Decodable {
        struct RegModels: Decodable {
            let regModel1st: [String: String]
            let regModel2nd: [String: String]
        }
        let manufacturers: [String: String]
        let regulators: [String: RegModels]
    }

    struct SizesOptionsDTO: Decodable {
        let sizes: [String: String]
        let manufacturers: [String: String]
    }

    // MARK: - Category

    enum Category: CaseIterable, Identifiable {
        case tank, regulator, equipment

        var id: String { "\(self)" }

        var displayName: String {
            switch self {
            case .tank: return "Tauchgeräte"
            case .regulator: return "Atemregler"
            case .equipment: return "Equipment"
            }
        }

        /// Das muss mit deinem Backend-`asset_type` zusammenpassen.
        var assetType: String {
            switch self {
            case .tank: return "tl_dc_tanks"
            case .regulator: return "tl_dc_regulators"
            case .equipment: return "tl_dc_equipment"
            }
        }
    }

    // MARK: - Published state

    @Published var members: [MemberService.Member] = []

    @Published var selectedCategory: Category = .equipment
    @Published var isLoading = false
    @Published var isSubmitting = false
    @Published var errorMessage: String? = nil
    @Published var submitSuccess = false

    @Published var availableItems: [Int: ItemDisplay] = [:]
    @Published var selectedDrafts: [Draft] = []

    @Published var reservations: [EquipmentReservation] = []

    // MARK: - Private caches

    private var equipmentIndex: [Int: EquipmentDTO] = [:]
    private var equipmentOptions: EquipmentOptionsDTO?
    private var regulatorOptions: RegulatorOptionsDTO?
    private var sizesOptions: SizesOptionsDTO?

    // MARK: - Label mapping helpers (Equipment)

    private func typeLabel(for typeKey: String?) -> String? {
        guard let key = typeKey, let opts = equipmentOptions?.types[key] else { return nil }
        return opts.name
    }

    private func subTypeLabel(for typeKey: String?, subKey: String?) -> String? {
        guard let tKey = typeKey, let sKey = subKey,
              let type = equipmentOptions?.types[tKey],
              let label = type.subtypes[sKey] else { return nil }
        return label
    }

    // MARK: - Members

    func loadMembers() async {
        do {
            let list = try await MemberService.shared.loadMembers()
            self.members = list.sorted {
                $0.fullName.localizedCaseInsensitiveCompare($1.fullName) == .orderedAscending
            }
            #if DEBUG
            print("✅ loaded members:", members.count)
            #endif
        } catch {
            self.members = []
            self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription

            #if DEBUG
            print("❌ loadMembers failed:", error)
            #endif
        }
    }

    // MARK: - Load Items per Category

    func loadItems(for category: Category) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            switch category {

            case .tank:
                let tanks: [TankDTO] = try await APIClient.shared.request("tanks")

                let available = tanks.filter { t in
                    (t.status ?? "").lowercased() == "available"
                }

                var map: [Int: ItemDisplay] = [:]
                for t in available {

                    let subtitleParts: [String] = [
                        // Inventar ist bereits im Title, aber hier ggf. nochmal/zusätzlich:
                        // "Inventar: #\(t.id)",

                        t.serialNumber?.isEmpty == false ? "SN: \(t.serialNumber!)" : nil,
                        t.manufacturer?.isEmpty == false ? "Hersteller: \(t.manufacturer!)" : nil,
                        t.bazNumber?.isEmpty == false ? "BAZ: \(t.bazNumber!)" : nil,
                        t.size?.isEmpty == false ? "Größe: \(t.size!) L" : nil
                    ].compactMap { $0 }

                    let subtitle = subtitleParts.isEmpty
                        ? t.displaySubtitle
                        : subtitleParts.joined(separator: "\n")

                    map[t.id] = ItemDisplay(
                        title: t.displayTitle,          // ✅ enthält "Flasche #id …"
                        subtitle: subtitle,             // ✅ enthält Hersteller/BAZ/Größe/SN
                        groupTitle: nil
                    )
                }
                availableItems = map

            case .regulator:
                // ✅ volle DTOs nutzen -> displaySubtitle enthält Models + SNs + Notes
                let regs: [RegulatorDTO] = try await APIClient.shared.request("regulators")
                let available = regs.filter { ($0.status ?? "").lowercased() == "available" }

                var map: [Int: ItemDisplay] = [:]
                for r in available {
                    map[r.id] = ItemDisplay(
                        title: r.displayTitle,
                        subtitle: r.displaySubtitle,   // ✅ Modell 1st/2ndPri/2ndSec + Seriennummern
                        groupTitle: nil
                    )
                }
                availableItems = map

            case .equipment:
                // ✅ volle DTOs nutzen -> displaySubtitle enthält Labels, Hersteller, Größe, Modell, Farbe, Notes
                let eq: [EquipmentDTO] = try await APIClient.shared.request("equipment")
                let available = eq.filter { ($0.status ?? "").lowercased() == "available" }

                var map: [Int: ItemDisplay] = [:]
                for e in available {
                    map[e.id] = ItemDisplay(
                        title: e.displayTitle,
                        subtitle: e.displaySubtitle,
                        groupTitle: e.type_label // ✅ Gruppierung nach Typ-Label (z.B. "Anzug", "Maske", ...)
                    )
                }
                availableItems = map
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            availableItems = [:]
        }
    }

    // MARK: - Draft selection

    func addSelectedItem(selectedId: Int?, notes: String?) {
        guard let id = selectedId else { return }

        // ✅ hole Anzeige aus availableItems (dort baust du bei Reglern bereits Models zusammen!)
        let display = availableItems[id]
        let title = display?.title ?? "#\(id)"
        let subtitle = display?.subtitle

        switch selectedCategory {
        case .tank:
            selectedDrafts.append(
                Draft(
                    itemId: id,
                    itemType: Category.tank.assetType,
                    types: nil,
                    subType: nil,
                    notes: notes,
                    displayTitle: title,
                    displaySubtitle: subtitle
                )
            )

        case .regulator:
            selectedDrafts.append(
                Draft(
                    itemId: id,
                    itemType: Category.regulator.assetType,
                    types: nil,
                    subType: nil,
                    notes: notes,
                    displayTitle: title,
                    displaySubtitle: subtitle // ✅ enthält jetzt regModel1st/2ndPri/2ndSec Labels
                )
            )

        case .equipment:
            let e = equipmentIndex[id]
            selectedDrafts.append(
                Draft(
                    itemId: id,
                    itemType: Category.equipment.assetType,
                    types: e?.types,
                    subType: e?.sub_type,
                    notes: notes,
                    displayTitle: title,
                    displaySubtitle: subtitle
                )
            )
        }
    }

    // MARK: - Submit reservation

    func submitReservation(reservedFor: Int? = nil) async {
        guard !isSubmitting else { return }
        guard let memberId = AuthManager.shared.currentMemberIdInt else {
            errorMessage = "Nicht eingeloggt."
            return
        }

        isSubmitting = true
        errorMessage = nil
        submitSuccess = false
        defer { isSubmitting = false }

        // asset_type: if multiple categories picked, use "multiple"
        let uniqueTypes = Set(selectedDrafts.map { $0.itemType })
        let assetType = uniqueTypes.count > 1 ? "multiple" : (uniqueTypes.first ?? selectedCategory.assetType)

        let items: [CreateReservationItem] = selectedDrafts.map { d in
            CreateReservationItem(
                itemId: d.itemId,
                itemType: d.itemType,
                types: d.itemType == Category.equipment.assetType ? d.types : nil,
                subType: d.itemType == Category.equipment.assetType ? d.subType : nil,
                notes: d.notes
            )
        }

        let payload = CreateReservationRequest(
            memberId: memberId,
            reservedFor: reservedFor ?? memberId,
            assetType: assetType,
            items: items
        )

        do {
            let _: EquipmentReservation = try await APIClient.shared.request("reservations", method: "POST", body: payload)
            submitSuccess = true
            selectedDrafts.removeAll()
            availableItems = [:]
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    // MARK: - Load existing reservations (optional)

    func loadReservations() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let list: [EquipmentReservation] = try await APIClient.shared.request("reservations")
            reservations = list
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            reservations = []
        }
    }
}
