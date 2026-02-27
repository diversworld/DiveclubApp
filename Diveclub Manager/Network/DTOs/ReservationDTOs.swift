//
//  ReservationDTO.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 10.02.26.
//

import Foundation

struct ReservationDTO: Decodable, Identifiable {
    let id: Int
    let title: String?
    let reservationStatus: String?
    let memberId: Int?
    let notes: String?
    let reservedFor: Int?
    let assetType: String?
    let rentalFee: String?
    let reservedAt: Int?
    let pickedUpAt: Int?
    let returnedAt: Int?
    let items: [ReservationItemDTO]?

    private enum CodingKeys: String, CodingKey {
        case id, title, notes, reservedFor, rentalFee, items

        // snake_case
        case reservationStatus_snake = "reservation_status"
        case memberId_snake = "member_id"
        case assetType_snake = "asset_type"
        case reservedAt_snake = "reserved_at"
        case pickedUpAt_snake = "picked_up_at"
        case returnedAt_snake = "returned_at"

        // camelCase (falls Backend mischt)
        case reservationStatus_camel = "reservationStatus"
        case memberId_camel = "memberId"
        case assetType_camel = "assetType"
        case reservedAt_camel = "reservedAt"
        case pickedUpAt_camel = "pickedUpAt"
        case returnedAt_camel = "returnedAt"

        // mögliche alternative items keys (falls Backend so liefert)
        case items_alt1 = "reservationItems"
        case items_alt2 = "children"
        case items_alt3 = "positions"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id = try c.decode(Int.self, forKey: .id)
        title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        notes = try c.decodeIfPresent(String.self, forKey: .notes)
        reservedFor = try c.decodeIfPresent(Int.self, forKey: .reservedFor)

        // rentalFee kann String oder Number sein
        if let s = try? c.decodeIfPresent(String.self, forKey: .rentalFee) {
            rentalFee = s
        } else if let d = try? c.decodeIfPresent(Double.self, forKey: .rentalFee) {
            rentalFee = String(d)
        } else {
            rentalFee = nil
        }

        reservationStatus =
            (try? c.decodeIfPresent(String.self, forKey: .reservationStatus_snake)) ??
            (try? c.decodeIfPresent(String.self, forKey: .reservationStatus_camel))

        memberId =
            (try? c.decodeIfPresent(Int.self, forKey: .memberId_snake)) ??
            (try? c.decodeIfPresent(Int.self, forKey: .memberId_camel))

        assetType =
            (try? c.decodeIfPresent(String.self, forKey: .assetType_snake)) ??
            (try? c.decodeIfPresent(String.self, forKey: .assetType_camel))

        reservedAt =
            (try? c.decodeIfPresent(Int.self, forKey: .reservedAt_snake)) ??
            (try? c.decodeIfPresent(Int.self, forKey: .reservedAt_camel))

        pickedUpAt =
            (try? c.decodeIfPresent(Int.self, forKey: .pickedUpAt_snake)) ??
            (try? c.decodeIfPresent(Int.self, forKey: .pickedUpAt_camel))

        returnedAt =
            (try? c.decodeIfPresent(Int.self, forKey: .returnedAt_snake)) ??
            (try? c.decodeIfPresent(Int.self, forKey: .returnedAt_camel))

        // items: versuche mehrere keys
        items =
            (try? c.decodeIfPresent([ReservationItemDTO].self, forKey: .items)) ??
            (try? c.decodeIfPresent([ReservationItemDTO].self, forKey: .items_alt1)) ??
            (try? c.decodeIfPresent([ReservationItemDTO].self, forKey: .items_alt2)) ??
            (try? c.decodeIfPresent([ReservationItemDTO].self, forKey: .items_alt3))
    }
}

struct ReservationItemDTO: Decodable, Identifiable {
    let id: Int
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

    private enum CodingKeys: String, CodingKey {
        case id, types, notes

        // snake_case
        case itemType_snake = "item_type"
        case subType_snake = "sub_type"
        case reservationStatus_snake = "reservation_status"
        case itemId_snake = "item_id"
        case reservedAt_snake = "reserved_at"
        case pickedUpAt_snake = "picked_up_at"
        case returnedAt_snake = "returned_at"
        case createdAt_snake = "created_at"
        case updatedAt_snake = "updated_at"

        // camelCase fallback
        case itemType_camel = "itemType"
        case subType_camel = "subType"
        case reservationStatus_camel = "reservationStatus"
        case itemId_camel = "itemId"
        case reservedAt_camel = "reservedAt"
        case pickedUpAt_camel = "pickedUpAt"
        case returnedAt_camel = "returnedAt"
        case createdAt_camel = "createdAt"
        case updatedAt_camel = "updatedAt"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id = try c.decode(Int.self, forKey: .id)
        types = try c.decodeIfPresent(String.self, forKey: .types)
        notes = try c.decodeIfPresent(String.self, forKey: .notes)

        itemType =
            (try? c.decodeIfPresent(String.self, forKey: .itemType_snake)) ??
            (try? c.decodeIfPresent(String.self, forKey: .itemType_camel))

        subType =
            (try? c.decodeIfPresent(String.self, forKey: .subType_snake)) ??
            (try? c.decodeIfPresent(String.self, forKey: .subType_camel))

        reservationStatus =
            (try? c.decodeIfPresent(String.self, forKey: .reservationStatus_snake)) ??
            (try? c.decodeIfPresent(String.self, forKey: .reservationStatus_camel))

        itemId =
            (try? c.decodeIfPresent(Int.self, forKey: .itemId_snake)) ??
            (try? c.decodeIfPresent(Int.self, forKey: .itemId_camel))

        reservedAt =
            (try? c.decodeIfPresent(Int.self, forKey: .reservedAt_snake)) ??
            (try? c.decodeIfPresent(Int.self, forKey: .reservedAt_camel))

        pickedUpAt =
            (try? c.decodeIfPresent(Int.self, forKey: .pickedUpAt_snake)) ??
            (try? c.decodeIfPresent(Int.self, forKey: .pickedUpAt_camel))

        returnedAt =
            (try? c.decodeIfPresent(Int.self, forKey: .returnedAt_snake)) ??
            (try? c.decodeIfPresent(Int.self, forKey: .returnedAt_camel))

        createdAt =
            (try? c.decodeIfPresent(Int.self, forKey: .createdAt_snake)) ??
            (try? c.decodeIfPresent(Int.self, forKey: .createdAt_camel))

        updatedAt =
            (try? c.decodeIfPresent(Int.self, forKey: .updatedAt_snake)) ??
            (try? c.decodeIfPresent(Int.self, forKey: .updatedAt_camel))
    }
}
