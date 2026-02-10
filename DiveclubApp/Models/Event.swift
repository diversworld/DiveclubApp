//
//  Event.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import Foundation

/// /api/events/{id}
struct Event: Identifiable, Decodable, Equatable {
    let id: Int

    let title: String
    let description: String?

    let location: String?

    let courseId: Int?

    let currentParticipants: Int?
    let maxParticipants: Int?

    let dateStart: Date?
    let dateEnd: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case location

        case courseId = "course_id"

        case currentParticipants = "current_participants"
        case maxParticipants = "max_participants"

        // je nach Backend: "dateStart"/"dateEnd" oder snake_case
        case dateStart
        case dateEnd
        case date_start
        case date_end
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id = try c.decode(Int.self, forKey: .id)
        title = (try? c.decode(String.self, forKey: .title)) ?? "Event"
        description = try? c.decodeIfPresent(String.self, forKey: .description)
        location = try? c.decodeIfPresent(String.self, forKey: .location)

        courseId = try? c.decodeIfPresent(Int.self, forKey: .courseId)

        currentParticipants = try? c.decodeIfPresent(Int.self, forKey: .currentParticipants)
        maxParticipants = try? c.decodeIfPresent(Int.self, forKey: .maxParticipants)

        // tolerant: akzeptiert Int unix timestamp oder ISO-String (falls mal so)
        func decodeDate(_ keys: [CodingKeys]) -> Date? {
            for k in keys {
                if let intVal = try? c.decodeIfPresent(Int.self, forKey: k) {
                    return Date(timeIntervalSince1970: TimeInterval(intVal))
                }
                if let strVal = try? c.decodeIfPresent(String.self, forKey: k) {
                    if let intFromStr = Int(strVal) {
                        return Date(timeIntervalSince1970: TimeInterval(intFromStr))
                    }
                    // ISO8601 fallback
                    let iso = ISO8601DateFormatter()
                    if let d = iso.date(from: strVal) { return d }
                }
            }
            return nil
        }

        dateStart = decodeDate([.dateStart, .date_start])
        dateEnd = decodeDate([.dateEnd, .date_end])
    }
}
