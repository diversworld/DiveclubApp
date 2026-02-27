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
                // 1) Optionen laden (Klartext-Mapping)
                let opts: RegulatorOptionsDTO = try await APIClient.shared.request("regulator/options")
                self.regulatorOptions = opts

                // 2) Regler laden
                let regs: [RegulatorDTO] = try await APIClient.shared.request("regulators")
                let available = regs.filter { ($0.status ?? "").lowercased() == "available" }

                var map: [Int: ItemDisplay] = [:]
                for r in available {

                    let manLabel = regManufacturerLabel(r.manufacturer)

                    let m1 = regModel1Label(manufacturerId: r.manufacturer, modelKey: r.regModel1st)
                    let m2p = regModel2Label(manufacturerId: r.manufacturer, modelKey: r.regModel2ndPri)
                    let m2s = regModel2Label(manufacturerId: r.manufacturer, modelKey: r.regModel2ndSec)

                    let subtitleParts: [String] = [
                        manLabel.map { "Hersteller: \($0)" },

                        r.serialNumber1st?.isEmpty == false ? "1. Stufe: \(r.serialNumber1st!)" : nil,
                        m1?.isEmpty == false ? "Modell 1. Stufe: \(m1!)" : nil,

                        r.serialNumber2ndPri?.isEmpty == false ? "2. Stufe (prim): \(r.serialNumber2ndPri!)" : nil,
                        m2p?.isEmpty == false ? "Modell 2. Stufe (prim): \(m2p!)" : nil,

                        r.serialNumber2ndSec?.isEmpty == false ? "2. Stufe (sec): \(r.serialNumber2ndSec!)" : nil,
                        m2s?.isEmpty == false ? "Modell 2. Stufe (sec): \(m2s!)" : nil,

                        r.notes?.isEmpty == false ? r.notes : nil
                    ].compactMap { $0 }

                    map[r.id] = ItemDisplay(
                        title: r.displayTitle,
                        subtitle: subtitleParts.isEmpty ? nil : subtitleParts.joined(separator: "\n"),
                        groupTitle: nil
                    )
                }
                availableItems = map

            case .equipment:
                let eq: [EquipmentDTO] = try await APIClient.shared.request("equipment")
                let opts: EquipmentOptionsDTO = try await APIClient.shared.request("equipment/options")
                let sizes: SizesOptionsDTO = try await APIClient.shared.request("sizes/options")
                
                self.equipmentOptions = opts
                self.sizesOptions = sizes

                let available = eq.filter { ($0.status ?? "").lowercased() == "available" }

                // ✅ Index für spätere Submit Payload (types/subType)
                self.equipmentIndex = Dictionary(uniqueKeysWithValues: available.map { ($0.id, $0) })

                var map: [Int: ItemDisplay] = [:]
                for e in available {

                    // ✅ Gruppierung: Type-Label aus options
                    let group = typeLabel(for: e.types) ?? e.type_label ?? ""

                    // ✅ Subtype, Hersteller, Größe auflösen
                    let stLbl = subTypeLabel(for: e.types, subKey: e.sub_type) ?? e.sub_type_label
                    let manLbl: String? = {
                        if let key = e.manufacturer, let v = equipmentOptions?.manufacturers[key] { return v }
                        if let key = e.manufacturer, let v = sizesOptions?.manufacturers[key] { return v }
                        return e.manufacturer_label ?? e.manufacturer
                    }()

                    let sizeLbl: String? = {
                        // EquipmentDTO.size ist Int? → für options key als String
                        if let s = e.size, let v = sizesOptions?.sizes[String(s)] { return v }
                        if let s = e.size, let v = equipmentOptions?.sizes[String(s)] { return v }
                        return e.size_label
                    }()

                    let subtitleParts: [String] = [
                        stLbl?.isEmpty == false ? stLbl : nil,
                        manLbl?.isEmpty == false ? "Hersteller: \(manLbl!)" : nil,
                        sizeLbl?.isEmpty == false ? "Größe: \(sizeLbl!)" : nil,
                        e.model?.isEmpty == false ? "Modell: \(e.model!)" : nil,
                        e.color?.isEmpty == false ? "Farbe: \(e.color!)" : nil,
                        e.notes?.isEmpty == false ? e.notes : nil
                    ].compactMap { $0 }

                    map[e.id] = ItemDisplay(
                        title: e.displayTitle,
                        subtitle: subtitleParts.isEmpty ? nil : subtitleParts.joined(separator: "\n"),
                        groupTitle: group.isEmpty ? nil : group
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

        // ✅ eindeutiger Key pro Kategorie/AssetType + id
        let itemType = selectedCategory.assetType

        // ✅ bereits ausgewählt? -> nichts tun
        let alreadySelected = selectedDrafts.contains { $0.itemType == itemType && $0.itemId == id }
        if alreadySelected {
            // optional: kleine Meldung (wenn du willst, füge @Published duplicateMessage hinzu)
            return
        }

        // Anzeige aus availableItems
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
                    displaySubtitle: subtitle
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
    
    // MARK: - Label mapping helpers (Regulator)

    private func regManufacturerLabel(_ manufacturerId: String?) -> String? {
        guard let id = manufacturerId else { return nil }
        return regulatorOptions?.manufacturers[id] ?? manufacturerId
    }

    private func regModel1Label(manufacturerId: String?, modelKey: String?) -> String? {
        guard let man = manufacturerId, let key = modelKey else { return nil }
        return regulatorOptions?.regulators[man]?.regModel1st[key] ?? modelKey
    }

    private func regModel2Label(manufacturerId: String?, modelKey: String?) -> String? {
        guard let man = manufacturerId, let key = modelKey else { return nil }
        return regulatorOptions?.regulators[man]?.regModel2nd[key] ?? modelKey
    }
}
