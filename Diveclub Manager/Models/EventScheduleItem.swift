//
//  EventSchedule.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 08.02.26.
//

import Foundation
import Combine

struct EventScheduleItem: Decodable, Identifiable {

    let id: Int
    let moduleId: Int
    let moduleTitle: String
    let plannedAt: Date
    let location: String?
    let notes: String?

    // Wir akzeptieren beide Schreibweisen (mit und ohne convertFromSnakeCase)
    private enum CodingKeys: String, CodingKey {
        case id
        case moduleIdSnake = "module_id"
        case moduleIdCamel = "moduleId"

        case moduleTitleSnake = "module_title"
        case moduleTitleCamel = "moduleTitle"

        case plannedAtSnake = "planned_at"
        case plannedAtCamel = "plannedAt"

        case location
        case notes
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id = try c.decode(Int.self, forKey: .id)

        // moduleId: module_id oder moduleId
        if let v = try c.decodeIfPresent(Int.self, forKey: .moduleIdSnake) {
            moduleId = v
        } else if let v = try c.decodeIfPresent(Int.self, forKey: .moduleIdCamel) {
            moduleId = v
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys.moduleIdSnake,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Missing module_id/moduleId"
                )
            )
        }

        // moduleTitle: module_title oder moduleTitle
        if let t = try c.decodeIfPresent(String.self, forKey: .moduleTitleSnake) {
            moduleTitle = t
        } else if let t = try c.decodeIfPresent(String.self, forKey: .moduleTitleCamel) {
            moduleTitle = t
        } else {
            moduleTitle = "Modul \(moduleId)"
        }

        // plannedAt: planned_at oder plannedAt (Int oder String-Timestamp)
        let ts: Int?
        if let v = try c.decodeIfPresent(Int.self, forKey: .plannedAtSnake) {
            ts = v
        } else if let v = try c.decodeIfPresent(Int.self, forKey: .plannedAtCamel) {
            ts = v
        } else if let s = try c.decodeIfPresent(String.self, forKey: .plannedAtSnake),
                  let v = Int(s.trimmingCharacters(in: .whitespacesAndNewlines)) {
            ts = v
        } else if let s = try c.decodeIfPresent(String.self, forKey: .plannedAtCamel),
                  let v = Int(s.trimmingCharacters(in: .whitespacesAndNewlines)) {
            ts = v
        } else {
            ts = nil
        }

        if let ts {
            plannedAt = Date(timeIntervalSince1970: TimeInterval(ts))
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys.plannedAtSnake,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Missing planned_at/plannedAt"
                )
            )
        }

        location = try c.decodeIfPresent(String.self, forKey: .location)
        notes = try c.decodeIfPresent(String.self, forKey: .notes)
    }
}
