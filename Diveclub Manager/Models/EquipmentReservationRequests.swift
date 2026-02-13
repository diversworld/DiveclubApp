//
//  EquipmentReservationRequests.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 10.02.26.
//

import Foundation

struct CreateReservationRequest: Encodable {
    let reservedFor: Int?
    let eventId: Int?
    let assetType: String?
    let items: [CreateReservationItem]?

    enum CodingKeys: String, CodingKey {
        case reservedFor
        case eventId = "event_id"
        case assetType = "asset_type"
        case items
    }
}

struct CreateReservationItem: Encodable {
    let itemId: Int?
    let itemType: String?

    enum CodingKeys: String, CodingKey {
        case itemId = "item_id"
        case itemType = "item_type"
    }
}

struct CreateReservationResponse: Decodable, Equatable {
    let success: Bool
    let id: Int?
}
