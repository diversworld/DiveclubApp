import Foundation
import Combine

@MainActor
final class ReservationViewModel: ObservableObject {

    // MARK: - API DTOs / Items

    struct RegulatorItem: Decodable, Identifiable {
        let id: Int
        let title: String
        let status: String
        let brand: String?
        let model: String?
        let regModel1st: String?
        let regModel2ndPri: String?
        let regModel2ndSec: String?
    }

    struct EquipmentItem: Decodable, Identifiable {
        let id: Int
        let title: String
        let status: String
        let types: String?
        let sub_type: String?
        let brand: String?
        let size: String?
        let model: String?
        let color: String?

        enum CodingKeys: String, CodingKey {
            case id, title, status
            case types
            case sub_type
            case brand, size
            case model, color
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)

            id = try c.decode(Int.self, forKey: .id)
            title = (try? c.decode(String.self, forKey: .title)) ?? "#\(id)"
            status = (try? c.decode(String.self, forKey: .status)) ?? ""

            brand = try? c.decodeIfPresent(String.self, forKey: .brand)
            size  = try? c.decodeIfPresent(String.self, forKey: .size)
            model = try? c.decodeIfPresent(String.self, forKey: .model)
            color = try? c.decodeIfPresent(String.self, forKey: .color)

            func decodeStringOrInt(_ key: CodingKeys) -> String? {
                if let s = try? c.decodeIfPresent(String.self, forKey: key) { return s }
                if let i = try? c.decodeIfPresent(Int.self, forKey: key) { return String(i) }
                return nil
            }
            types    = decodeStringOrInt(.types)
            sub_type = decodeStringOrInt(.sub_type)
        }
    }

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

    private var equipmentIndex: [Int: EquipmentItem] = [:]
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
                let tanks: [Tank] = try await APIClient.shared.request("tanks")
                let uid = AuthManager.shared.currentMemberIdInt

                let available = tanks.filter { t in
                    let isAvailable = (t.status ?? "").lowercased() == "available"
                    let ownerMatches: Bool = {
                        if let owner = t.ownerMemberId, let uid { return owner == uid }
                        return true
                    }()
                    return isAvailable && ownerMatches
                }

                var map: [Int: ItemDisplay] = [:]
                for t in available {
                    map[t.id] = ItemDisplay(
                        title: t.displayTitle,
                        subtitle: nil,
                        groupTitle: nil
                    )
                }
                availableItems = map

            case .regulator:
                let regOpts: RegulatorOptionsDTO = try await APIClient.shared.request("regulator/options")
                self.regulatorOptions = regOpts

                let regs: [RegulatorItem] = try await APIClient.shared.request("regulators")
                let available = regs.filter { $0.status.lowercased() == "available" }

                var map: [Int: ItemDisplay] = [:]
                for r in available {

                    let brandLabel: String? = {
                        guard let brandId = r.brand,
                              let dict = regulatorOptions?.manufacturers
                        else { return nil }
                        return dict[brandId]
                    }()

                    let modelsForBrand = r.brand.flatMap { regulatorOptions?.regulators[$0] }

                    let model1Label: String? = {
                        guard let key = r.regModel1st,
                              let map = modelsForBrand?.regModel1st
                        else { return nil }
                        return map[key]
                    }()

                    let model2PriLabel: String? = {
                        guard let key = r.regModel2ndPri,
                              let map = modelsForBrand?.regModel2nd
                        else { return nil }
                        return map[key]
                    }()

                    let model2SecLabel: String? = {
                        guard let key = r.regModel2ndSec,
                              let map = modelsForBrand?.regModel2nd
                        else { return nil }
                        return map[key]
                    }()

                    let extra = [brandLabel, model1Label, model2PriLabel, model2SecLabel]
                        .compactMap { $0 }
                        .joined(separator: " ")

                    map[r.id] = ItemDisplay(
                        title: r.title,
                        subtitle: extra.isEmpty ? nil : extra,
                        groupTitle: nil
                    )
                }

                availableItems = map

            case .equipment:
                // Items
                let eq: [EquipmentItem] = try await APIClient.shared.request("equipment")
                let available = eq.filter { $0.status.lowercased() == "available" }

                // Options for mapping
                let opts: EquipmentOptionsDTO = try await APIClient.shared.request("equipment/options")
                self.equipmentOptions = opts

                let sizesOpts: SizesOptionsDTO = try await APIClient.shared.request("sizes/options")
                self.sizesOptions = sizesOpts

                equipmentIndex = Dictionary(uniqueKeysWithValues: available.map { ($0.id, $0) })

                var map: [Int: ItemDisplay] = [:]
                for e in available {
                    let tLabel  = typeLabel(for: e.types)
                    let stLabel = subTypeLabel(for: e.types, subKey: e.sub_type)

                    let mLabel: String? = {
                        if let key = e.brand, let dict = equipmentOptions?.manufacturers, let v = dict[key] { return v }
                        if let key = e.brand, let dict = sizesOptions?.manufacturers, let v = dict[key] { return v }
                        return e.brand
                    }()

                    let sLabel: String? = {
                        if let key = e.size, let dict = equipmentOptions?.sizes, let v = dict[key] { return v }
                        if let key = e.size, let dict = sizesOptions?.sizes, let v = dict[key] { return v }
                        return e.size
                    }()

                    let infoParts = [stLabel, mLabel, sLabel, e.model, e.color].compactMap { $0 }
                    let subtitle = infoParts.isEmpty ? nil : infoParts.joined(separator: ", ")

                    map[e.id] = ItemDisplay(
                        title: e.title,
                        subtitle: subtitle,
                        groupTitle: tLabel
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

        switch selectedCategory {
        case .tank:
            selectedDrafts.append(
                Draft(itemId: id, itemType: Category.tank.assetType, types: nil, subType: nil, notes: notes)
            )

        case .regulator:
            selectedDrafts.append(
                Draft(itemId: id, itemType: Category.regulator.assetType, types: nil, subType: nil, notes: notes)
            )

        case .equipment:
            let e = equipmentIndex[id]
            selectedDrafts.append(
                Draft(itemId: id, itemType: Category.equipment.assetType, types: e?.types, subType: e?.sub_type, notes: notes)
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
