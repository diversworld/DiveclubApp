//
//  EventSchedule.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 08.02.26.
//

import Foundation

struct EventScheduleItem: Codable, Identifiable {
    let id: Int
    let title: String?
    let start: Int?        // Unix seconds
    let end: Int?          // Unix seconds
    let location: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case start
        case end
        case location
        case notes
    }

    var startDate: Date? {
        guard let start else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(start))
    }

    var endDate: Date? {
        guard let end else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(end))
    }
}
