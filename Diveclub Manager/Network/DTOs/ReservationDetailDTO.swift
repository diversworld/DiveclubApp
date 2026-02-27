//
//  ReservationDetailDTO.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 26.02.26.
//
//
//  ReservationDetailDTO.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 26.02.26.
//

import Foundation

// WICHTIG:
// Wenn APIClient JSONDecoder.keyDecodingStrategy = .convertFromSnakeCase nutzt,
// dann dürfen hier KEINE CodingKeys mit snake_case Raw-Values verwendet werden,
// sonst wird z.B. reservation_status -> reservationStatus konvertiert und nicht mehr gefunden.

struct ReservationDetailDTO: Decodable, Identifiable {
    let id: Int
    let title: String?

    // kommt als reservation_status (snake_case) -> wird zu reservationStatus konvertiert
    let reservationStatus: String?

    // asset_type -> assetType
    let assetType: String?

    // member_id -> memberId
    let memberId: Int?

    // reservedFor kommt bei dir camelCase im JSON
    let reservedFor: Int?

    // event_id -> eventId
    let eventId: Int?

    // rentalFee kommt bei dir camelCase im JSON
    let rentalFee: String?

    let notes: String?

    // reserved_at -> reservedAt
    let reservedAt: Int?

    // picked_up_at -> pickedUpAt
    let pickedUpAt: Int?

    // returned_at -> returnedAt
    let returnedAt: Int?

    // optionaler Fallback (falls Backend Modelle auf Reservation-Ebene liefert)
    let regModel1st: String?
    let regModel2ndPri: String?
    let regModel2ndSec: String?

    let items: [ReservationDetailItemDTO]?
}

struct ReservationDetailItemDTO: Decodable, Identifiable {
    // Backend liefert oft KEINE echte item-id → synthetisch
    var id: String { "\(itemType ?? "unknown")-\(itemId ?? 0)-\(createdAt ?? 0)" }

    // item_id -> itemId
    let itemId: Int?

    // item_type -> itemType  (WICHTIG: sonst ist es nil)
    let itemType: String?

    let types: String?

    // sub_type -> subType
    let subType: String?

    // reservation_status -> reservationStatus
    let reservationStatus: String?

    let notes: String?

    // reserved_at -> reservedAt
    let reservedAt: Int?

    // picked_up_at -> pickedUpAt
    let pickedUpAt: Int?

    // returned_at -> returnedAt
    let returnedAt: Int?

    // created_at -> createdAt
    let createdAt: Int?

    // updated_at -> updatedAt
    let updatedAt: Int?

    // optional, falls Backend pro Item Modelle liefert:
    let regModel1st: String?
    let regModel2ndPri: String?
    let regModel2ndSec: String?
}
