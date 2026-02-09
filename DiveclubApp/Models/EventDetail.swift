//
//  EventDetail.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 08.02.26.
//

import Foundation

struct EventDetail: Decodable, Identifiable {

    let id: Int
    let title: String
    let description: String?
    let location: String?
    let dateStart: Date?
    let dateEnd: Date?
    let courseId: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case location
        case dateStart
        case dateEnd
        case courseId = "courseId"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id = try c.decode(Int.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        location = try c.decodeIfPresent(String.self, forKey: .location)
        courseId = try c.decodeIfPresent(Int.self, forKey: .courseId)

        // ✅ Unix Timestamp (Sekunden) → Date
        if let ts = try c.decodeIfPresent(Int.self, forKey: .dateStart) {
            dateStart = Date(timeIntervalSince1970: TimeInterval(ts))
        } else {
            dateStart = nil
        }

        if let ts = try c.decodeIfPresent(Int.self, forKey: .dateEnd) {
            dateEnd = Date(timeIntervalSince1970: TimeInterval(ts))
        } else {
            dateEnd = nil
        }
    }
}
