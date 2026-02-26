//
//  EquipmentReservationRequest.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 10.02.26.
//

import Foundation

struct EquipmentReservationRequest: Codable {
    let memberId: Int
    let reservedFor: ReservedFor
    let assetType: String
    let items: [Item]
    let notes: String?

    struct ReservedFor: Codable {
        let start: Int
        let end: Int
    }

    struct Item: Codable {
        let assetType: String
        let assetId: Int
        let quantity: Int

        /// type key from /api/equipment/options (z.B. "1")
        let types: String?

        /// subtype key from /api/equipment/options (z.B. "4")
        let subType: String?

        /// optional notes per item
        let notes: String?

        enum CodingKeys: String, CodingKey {
            case assetType = "asset_type"
            case assetId = "asset_id"
            case quantity
            case types
            case subType = "sub_type"
            case notes
        }
    }

    enum CodingKeys: String, CodingKey {
        case memberId = "member_id"
        case reservedFor = "reserved_for"
        case assetType = "asset_type"
        case items
        case notes
    }
}
