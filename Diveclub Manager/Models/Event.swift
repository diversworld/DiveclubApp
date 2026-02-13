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
    let price: String?

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
        case price

        // course id
        case courseId = "course_id"
        case courseIdCamel = "courseId"

        // participants
        case currentParticipants
        case currentParticipantsSnake = "current_participants"
        case maxParticipants
        case maxParticipantsSnake = "max_participants"

        // dates
        case dateStart
        case dateStartSnake = "date_start"
        case dateEnd
        case dateEndSnake = "date_end"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id = try c.decode(Int.self, forKey: .id)
        title = (try? c.decode(String.self, forKey: .title)) ?? "Event"
        description = try c.decodeIfPresent(String.self, forKey: .description)

        location = try c.decodeIfPresent(String.self, forKey: .location)
        price = try c.decodeIfPresent(String.self, forKey: .price)

        courseId = Self.decodeInt(from: c, keys: [.courseId, .courseIdCamel])

        currentParticipants = Self.decodeInt(from: c, keys: [.currentParticipants, .currentParticipantsSnake])
        maxParticipants = Self.decodeInt(from: c, keys: [.maxParticipants, .maxParticipantsSnake])

        dateStart = Self.decodeDate(from: c, keys: [.dateStart, .dateStartSnake])
        dateEnd = Self.decodeDate(from: c, keys: [.dateEnd, .dateEndSnake])
    }

    // MARK: - Helpers

    private static func decodeInt(from c: KeyedDecodingContainer<CodingKeys>, keys: [CodingKeys]) -> Int? {
        for k in keys {
            if let v = try? c.decodeIfPresent(Int.self, forKey: k) { return v }
            if let s = try? c.decodeIfPresent(String.self, forKey: k), let v = Int(s) { return v }
        }
        return nil
    }

    private static func decodeDate(from c: KeyedDecodingContainer<CodingKeys>, keys: [CodingKeys]) -> Date? {
        for k in keys {
            // unix int
            if let intVal = try? c.decodeIfPresent(Int.self, forKey: k) {
                return Date(timeIntervalSince1970: TimeInterval(intVal))
            }
            // unix string oder iso string
            if let strVal = try? c.decodeIfPresent(String.self, forKey: k) {
                if let intFromStr = Int(strVal) {
                    return Date(timeIntervalSince1970: TimeInterval(intFromStr))
                }
                let iso = ISO8601DateFormatter()
                if let d = iso.date(from: strVal) { return d }
            }
        }
        return nil
    }
}
