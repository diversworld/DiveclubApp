//
//  TankCheckDTOs.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 09.02.26.
//

import Foundation

// MARK: - /api/tank-checks (Liste)

struct TankCheckProposalDTO: Decodable, Identifiable, Equatable {
    let id: Int
    let title: String
    let published: Bool
    let proposalDate: Int?

    // manchmal kommt vendorName nur im Detail – optional halten, falls Backend es doch liefert
    let vendorName: String?

    enum CodingKeys: String, CodingKey {
        case id, title, published, vendorName
        case proposalDate
    }
}

// MARK: - /api/tank-checks/{id} (Detail inkl. Artikeln)

struct TankCheckProposalDetailDTO: Decodable, Identifiable, Equatable {
    let id: Int
    let title: String
    let published: Bool
    let proposalDate: Int?
    let vendorName: String?
    let notes: String?
    let articles: [TankCheckArticleDTO]

    enum CodingKeys: String, CodingKey {
        case id, title, published, proposalDate, vendorName, notes, articles
    }
}

struct TankCheckArticleDTO: Decodable, Identifiable, Equatable {
    let id: Int
    let title: String
    let isDefault: Bool
    let published: Bool

    /// "8", "10", "80", "15", "" ...
    let articleSize: String?

    /// Preise kommen als Strings
    let articlePriceBrutto: String?
    let articlePriceNetto: String?

    var priceBruttoDecimal: Decimal {
        Decimal(string: (articlePriceBrutto ?? "0").replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    enum CodingKeys: String, CodingKey {
        case id, title, published
        case isDefault = "default"
        case articleSize
        case articlePriceNetto
        case articlePriceBrutto
    }
}

// Backend: { "success": true, "id": 123 }
struct TankCheckBookingResponseDTO: Decodable {
    let success: Bool?
    let id: Int?
}
