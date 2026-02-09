//
//  TankCheckDetail.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 09.02.26.
//

import Foundation

struct TankCheckDetail: Codable, Identifiable {
    let id: Int
    let title: String?
    let plannedAt: Int?
    let location: String?
    let description: String?

    let priceTuv: Double?
    let priceO2Service: Double?
    let priceVisual: Double?

    // Optional: falls Backend Teilnehmer/Buchungen liefert
    let bookedCount: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case plannedAt = "planned_at"
        case location
        case description
        case priceTuv = "price_tuv"
        case priceO2Service = "price_o2_service"
        case priceVisual = "price_visual"
        case bookedCount = "booked_count"
    }

    var displayTitle: String { (title?.isEmpty == false) ? title! : "TÜV Termin #\(id)" }
}
