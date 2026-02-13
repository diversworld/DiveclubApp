//
//  EquipmentReservation.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 10.02.26.
//

import Foundation

// GET /api/reservations
struct EquipmentReservation: Decodable, Identifiable {
    let id: Int
    let title: String?
    let reservationStatus: String?
    let assetType: String?

    let memberId: Int?
    let reservedFor: Int?
    let eventId: Int?

    let rentalFee: String?
    let notes: String?

    // Timestamps (Unix seconds)
    let reservedAt: Int?
    let pickedUpAt: Int?
    let returnedAt: Int?

    let items: [EquipmentReservationItem]?

    enum CodingKeys: String, CodingKey {
        case id, title, notes, items
        case reservationStatus = "reservation_status"
        case assetType = "asset_type"
        case memberId = "member_id"
        case reservedFor
        case eventId = "event_id"
        case rentalFee
        case reservedAt = "reserved_at"
        case pickedUpAt = "picked_up_at"
        case returnedAt = "returned_at"
    }
}

struct EquipmentReservationItem: Decodable, Identifiable {
    let itemId: Int?
    let itemType: String?
    let reservationStatus: String?

    // stabile "synthetische" ID (weil items evtl. keine eigene id liefern)
    var id: String { "\(itemType ?? "unknown")-\(itemId ?? 0)" }

    enum CodingKeys: String, CodingKey {
        case itemId = "item_id"
        case itemType = "item_type"
        case reservationStatus = "reservation_status"
    }
}
