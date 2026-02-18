//
//  EquipmentReservationRequests.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 10.02.26.
//

import Foundation

struct CreateReservationRequest: Encodable {
    let memberId: Int
    let reservedFor: Int?
    let eventId: Int?
    let assetType: String?
    let items: [CreateReservationItem]?

    enum CodingKeys: String, CodingKey {
        case memberId = "member_id"
        case reservedFor
        case eventId = "event_id"
        case assetType = "asset_type"
        case items
    }
}

struct CreateReservationItem: Encodable {
    let itemId: Int?
    let itemType: String?
    let types: [Int]?
    let subType: Int?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case itemId = "item_id"
        case itemType = "item_type"
        case types
        case subType = "sub_type"
        case notes
    }
}

struct CreateReservationResponse: Decodable, Equatable {
    let success: Bool
    let id: Int?
}
