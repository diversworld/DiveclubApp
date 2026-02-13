//
//  TankCheckBookRequest.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 13.02.26.
//


import Foundation

/// POST /api/tank-checks/book
struct TankCheckBookRequest: Encodable {
    let proposalId: Int
    let notes: String?
    let items: [TankCheckBookItemRequest]

    enum CodingKeys: String, CodingKey {
        case proposalId = "proposal_id"   // ✅ wichtig
        case notes
        case items
    }
}

struct TankCheckBookItemRequest: Encodable {
    let serialNumber: String
    let manufacturer: String?
    let bazNumber: String?
    let size: String
    let o2clean: Bool
    let articles: [Int]
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case serialNumber
        case manufacturer
        case bazNumber
        case size
        case o2clean
        case articles
        case notes
    }
}
