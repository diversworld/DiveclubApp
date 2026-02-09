//
//  TankCheckDTOs.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 09.02.26.
//

import Foundation

// MARK: - LIST (GET /api/tank-checks)
// Falls die Liste dasselbe Schema wie Detail liefert, passt das.
// Wenn die Liste anders aussieht, sag kurz Bescheid, dann passen wir es an.
struct TankCheckProposalDTO: Identifiable, Decodable, Equatable {
    let id: Int
    let published: Bool?
    let tstamp: Date?
    let title: String?
    let alias: String?
    let checkId: Int?
    let proposalDate: Date?
    let vendorName: String?

    enum CodingKeys: String, CodingKey {
        case id, published, tstamp, title, alias
        case checkId
        case proposalDate
        case vendorName
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id = try c.decode(Int.self, forKey: .id)
        published = try c.decodeIfPresent(Bool.self, forKey: .published)

        if let ts = try c.decodeIfPresent(Int.self, forKey: .tstamp) {
            tstamp = Date(timeIntervalSince1970: TimeInterval(ts))
        } else {
            tstamp = nil
        }

        title = try c.decodeIfPresent(String.self, forKey: .title)
        alias = try c.decodeIfPresent(String.self, forKey: .alias)
        checkId = try c.decodeIfPresent(Int.self, forKey: .checkId)

        if let pd = try c.decodeIfPresent(Int.self, forKey: .proposalDate) {
            proposalDate = Date(timeIntervalSince1970: TimeInterval(pd))
        } else {
            proposalDate = nil
        }

        vendorName = try c.decodeIfPresent(String.self, forKey: .vendorName)
    }
}

// MARK: - DETAIL (GET /api/tank-checks/{id})
struct TankCheckProposalDetailDTO: Identifiable, Decodable, Equatable {
    let id: Int
    let published: Bool
    let tstamp: Date?
    let title: String
    let alias: String?
    let checkId: Int?
    let proposalDate: Date?

    let vendorName: String?
    let vendorWebsite: String?
    let vendorStreet: String?
    let vendorPostal: String?
    let vendorCity: String?
    let vendorEmail: String?
    let vendorPhone: String?
    let vendorMobile: String?

    let notesHTML: String?
    let addNotes: Bool?
    let sorting: Int?

    let articles: [TankCheckArticleDTO]

    enum CodingKeys: String, CodingKey {
        case id, published, tstamp, title, alias
        case checkId, proposalDate
        case vendorName, vendorWebsite, vendorStreet, vendorPostal, vendorCity
        case vendorEmail, vendorPhone, vendorMobile
        case notes
        case addNotes, sorting
        case articles
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id = try c.decode(Int.self, forKey: .id)
        published = (try? c.decode(Bool.self, forKey: .published)) ?? false

        if let ts = try c.decodeIfPresent(Int.self, forKey: .tstamp) {
            tstamp = Date(timeIntervalSince1970: TimeInterval(ts))
        } else {
            tstamp = nil
        }

        title = (try? c.decode(String.self, forKey: .title)) ?? "TÜV-Angebot"
        alias = try c.decodeIfPresent(String.self, forKey: .alias)
        checkId = try c.decodeIfPresent(Int.self, forKey: .checkId)

        if let pd = try c.decodeIfPresent(Int.self, forKey: .proposalDate) {
            proposalDate = Date(timeIntervalSince1970: TimeInterval(pd))
        } else {
            proposalDate = nil
        }

        vendorName = try c.decodeIfPresent(String.self, forKey: .vendorName)
        vendorWebsite = try c.decodeIfPresent(String.self, forKey: .vendorWebsite)
        vendorStreet = try c.decodeIfPresent(String.self, forKey: .vendorStreet)
        vendorPostal = try c.decodeIfPresent(String.self, forKey: .vendorPostal)
        vendorCity = try c.decodeIfPresent(String.self, forKey: .vendorCity)
        vendorEmail = try c.decodeIfPresent(String.self, forKey: .vendorEmail)
        vendorPhone = try c.decodeIfPresent(String.self, forKey: .vendorPhone)
        vendorMobile = try c.decodeIfPresent(String.self, forKey: .vendorMobile)

        notesHTML = try c.decodeIfPresent(String.self, forKey: .notes)
        addNotes = try c.decodeIfPresent(Bool.self, forKey: .addNotes)
        sorting = try c.decodeIfPresent(Int.self, forKey: .sorting)

        articles = (try? c.decode([TankCheckArticleDTO].self, forKey: .articles)) ?? []
    }
}

struct TankCheckArticleDTO: Identifiable, Decodable, Equatable {
    let id: Int
    let isDefault: Bool
    let published: Bool
    let pid: Int?
    let tstamp: Date?
    let title: String
    let articleSize: String?
    let articlePriceNetto: Decimal?
    let articlePriceBrutto: Decimal?
    let articleNotes: String?
    let addArticleNotes: Bool?
    let sorting: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case isDefault = "default"
        case published, pid, tstamp, title
        case articleSize, articlePriceNetto, articlePriceBrutto
        case articleNotes
        case addArticleNotes
        case sorting
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id = try c.decode(Int.self, forKey: .id)
        isDefault = (try? c.decode(Bool.self, forKey: .isDefault)) ?? false
        published = (try? c.decode(Bool.self, forKey: .published)) ?? false
        pid = try c.decodeIfPresent(Int.self, forKey: .pid)

        if let ts = try c.decodeIfPresent(Int.self, forKey: .tstamp) {
            tstamp = Date(timeIntervalSince1970: TimeInterval(ts))
        } else {
            tstamp = nil
        }

        title = (try? c.decode(String.self, forKey: .title)) ?? "Artikel"
        articleSize = try c.decodeIfPresent(String.self, forKey: .articleSize)

        func decodeDecimal(_ key: CodingKeys) -> Decimal? {
            guard let s = try? c.decodeIfPresent(String.self, forKey: key) else { return nil }
            return Decimal(string: s.replacingOccurrences(of: ",", with: "."))
        }
        articlePriceNetto = decodeDecimal(.articlePriceNetto)
        articlePriceBrutto = decodeDecimal(.articlePriceBrutto)

        articleNotes = try c.decodeIfPresent(String.self, forKey: .articleNotes)
        addArticleNotes = try c.decodeIfPresent(Bool.self, forKey: .addArticleNotes)
        sorting = try c.decodeIfPresent(Int.self, forKey: .sorting)
    }
}

// MARK: - BOOK (POST /api/tank-checks/book)
// Diese Typen müssen Encodable sein -> hier als Codable, aber NUR EINMAL im Projekt!
struct TankCheckBookingPayload: Codable, Equatable {
    let proposalId: Int
    let notes: String?
    let items: [TankCheckBookingItemPayload]

    enum CodingKeys: String, CodingKey {
        case proposalId = "proposal_id"
        case notes
        case items
    }
}

struct TankCheckBookingItemPayload: Codable, Equatable {
    let serialNumber: String
    let manufacturer: String?
    let bazNumber: String?
    let size: String?
    let o2clean: Bool?
    let articles: [Int]
    let notes: String?
}

struct TankCheckBookingResponseDTO: Decodable, Equatable {
    let bookingId: Int?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case bookingId = "booking_id"
        case message
    }
}
