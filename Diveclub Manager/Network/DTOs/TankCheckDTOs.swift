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
    let vendorName: String?

    /// ✅ Wichtig: Prüfungstermin-ID (kommt als checkId oder check_id)
    let checkId: Int?

    private enum CodingKeys: String, CodingKey {
        case id, title, published, vendorName, proposalDate
        case checkId
        case check_id
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id = try c.decode(Int.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        published = (try? c.decode(Bool.self, forKey: .published)) ?? false
        proposalDate = try c.decodeIfPresent(Int.self, forKey: .proposalDate)
        vendorName = try c.decodeIfPresent(String.self, forKey: .vendorName)

        // robust: checkId kann camelCase oder snake_case sein
        checkId =
            (try? c.decodeIfPresent(Int.self, forKey: .checkId)) ??
            (try? c.decodeIfPresent(Int.self, forKey: .check_id))
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

    /// ✅ Wichtig: Prüfungstermin-ID (kommt als checkId oder check_id)
    let checkId: Int?

    private enum CodingKeys: String, CodingKey {
        case id, title, published, proposalDate, vendorName, notes, articles
        case checkId
        case check_id
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id = try c.decode(Int.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        published = (try? c.decode(Bool.self, forKey: .published)) ?? false
        proposalDate = try c.decodeIfPresent(Int.self, forKey: .proposalDate)
        vendorName = try c.decodeIfPresent(String.self, forKey: .vendorName)
        notes = try c.decodeIfPresent(String.self, forKey: .notes)
        articles = (try? c.decode([TankCheckArticleDTO].self, forKey: .articles)) ?? []

        checkId =
            (try? c.decodeIfPresent(Int.self, forKey: .checkId)) ??
            (try? c.decodeIfPresent(Int.self, forKey: .check_id))
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
