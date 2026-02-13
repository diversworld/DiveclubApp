//
//  TankCheckBookingPayload.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 12.02.26.
//


import Foundation

/// POST /api/tank-checks/book
struct TankCheckBookingPayload: Encodable {
    let proposalId: Int
    let notes: String?
    let items: [TankCheckBookingItemPayload]

    enum CodingKeys: String, CodingKey {
        case proposalId = "proposal_id"   // ✅ Backend erwartet proposal_id
        case notes
        case items
    }
}

struct TankCheckBookingItemPayload: Encodable {
    let serialNumber: String
    let manufacturer: String?
    let bazNumber: String?
    let size: String
    let o2clean: Bool
    let articles: [Int]
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case serialNumber   // ✅ Backend-Beispiel: serialNumber (camelCase)
        case manufacturer
        case bazNumber      // ✅ Backend-Beispiel: bazNumber (camelCase)
        case size
        case o2clean         // ✅ Backend-Beispiel: o2clean
        case articles
        case notes
    }
}
