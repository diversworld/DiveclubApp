//
//  TankCheck.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import Foundation

struct TankCheckProposal: Codable, Identifiable {
    let id: Int
    let title: String?
    let eventId: Int?
    let plannedAt: Int?            // Unix Timestamp (Sekunden) oder nil
    let location: String?

    // Preise / Optionen (Beispiele)
    let priceTuv: Double?
    let priceO2Service: Double?
    let priceVisual: Double?

    let description: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case eventId = "event_id"
        case plannedAt = "planned_at"
        case location
        case priceTuv = "price_tuv"
        case priceO2Service = "price_o2_service"
        case priceVisual = "price_visual"
        case description
    }

    var displayTitle: String { (title?.isEmpty == false) ? title! : "TÜV Termin #\(id)" }
}
