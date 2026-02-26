//
//  CreateReservationRequest.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 26.02.26.
//

import Foundation

/// Item im Create-Reservation-Request.
/// Backend erwartet snake_case keys.
struct CreateReservationItem: Codable {
    let itemId: Int?
    let itemType: String
    let types: String?
    let subType: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case itemId = "item_id"
        case itemType = "item_type"
        case types
        case subType = "sub_type"
        case notes
    }

    init(
        itemId: Int?,
        itemType: String,
        types: String?,
        subType: String?,
        notes: String?
    ) {
        self.itemId = itemId
        self.itemType = itemType
        self.types = types
        self.subType = subType
        self.notes = notes
    }
}

/// Request zum Anlegen einer Reservierung.
struct CreateReservationRequest: Codable {
    let memberId: Int
    let reservedFor: Int
    let assetType: String
    let items: [CreateReservationItem]

    enum CodingKeys: String, CodingKey {
        case memberId = "member_id"
        case reservedFor = "reserved_for"
        case assetType = "asset_type"
        case items
    }

    init(
        memberId: Int,
        reservedFor: Int,
        assetType: String,
        items: [CreateReservationItem]
    ) {
        self.memberId = memberId
        self.reservedFor = reservedFor
        self.assetType = assetType
        self.items = items
    }
}
