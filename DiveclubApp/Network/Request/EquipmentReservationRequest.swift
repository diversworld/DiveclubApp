//
//  EquipmentReservationRequest.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 10.02.26.
//

import Foundation

struct EquipmentReservationRequest: Encodable {
    let memberId: Int
    let reservedFor: ReservedFor?
    let assetType: String?
    let items: [Item]

    struct ReservedFor: Encodable {
        let start: Int
        let end: Int
    }

    struct Item: Encodable {
        let assetType: String
        let assetId: Int
        let quantity: Int

        enum CodingKeys: String, CodingKey {
            case assetType = "asset_type"
            case assetId = "asset_id"
            case quantity
        }
    }

    enum CodingKeys: String, CodingKey {
        case memberId = "member_id"
        case reservedFor = "reserved_for"
        case assetType = "asset_type"
        case items
    }
}
