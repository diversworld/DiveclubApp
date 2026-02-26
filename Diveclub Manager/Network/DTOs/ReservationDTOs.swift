import Foundation

// MARK: - Reservation Response DTOs

struct ReservationDTO: Decodable, Identifiable {
    let id: Int
    let reservationStatus: String?
    let memberId: Int?
    let notes: String?
    let reservedFor: Int?
    let assetType: String?
    let reservedAt: Int?
    let pickedUpAt: Int?
    let returnedAt: Int?
    let items: [ReservationItemDTO]

    enum CodingKeys: String, CodingKey {
        case id
        case reservationStatus = "reservation_status"
        case memberId = "member_id"
        case notes
        case reservedFor
        case assetType = "asset_type"
        case reservedAt = "reserved_at"
        case pickedUpAt = "picked_up_at"
        case returnedAt = "returned_at"
        case items
    }
}

struct ReservationItemDTO: Decodable, Identifiable {
    let id: Int
    let pid: Int?
    let itemType: String?
    let types: String?
    let subType: String?
    let reservationStatus: String?
    let itemId: Int?
    let notes: String?
    let reservedAt: Int?
    let pickedUpAt: Int?
    let returnedAt: Int?
    let createdAt: Int?
    let updatedAt: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case pid
        case itemType = "item_type"
        case types
        case subType = "sub_type"
        case reservationStatus = "reservation_status"
        case itemId = "item_id"
        case notes
        case reservedAt = "reserved_at"
        case pickedUpAt = "picked_up_at"
        case returnedAt = "returned_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

