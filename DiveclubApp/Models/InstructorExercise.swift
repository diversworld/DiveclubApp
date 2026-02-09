//
//  InstructorExercise.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 08.02.26.
//

import Foundation

struct InstructorExercise: Codable, Identifiable {
    let id: Int

    let published: Bool?
    let pid: Int?
    let sorting: Int?
    let tstamp: Int?

    let exerciseId: Int?
    let title: String?

    var status: String
    let instructor: Int?

    // ✅ muss var sein, damit UI nach Save updaten kann
    var notes: String?

    let start: String?
    let stop: String?

    let moduleId: Int?
    var dateCompleted: Int?

    enum CodingKeys: String, CodingKey {
        case id, published, pid, sorting, tstamp
        case exerciseId = "exercise_id"
        case status, instructor, notes, start, stop
        case moduleId = "module_id"
        case dateCompleted

        // mögliche Titel-Keys
        case exerciseTitle = "exercise_title"
        case title
        case name
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id = try c.decode(Int.self, forKey: .id)
        published = try c.decodeIfPresent(Bool.self, forKey: .published)
        pid = try c.decodeIfPresent(Int.self, forKey: .pid)
        sorting = try c.decodeIfPresent(Int.self, forKey: .sorting)
        tstamp = try c.decodeIfPresent(Int.self, forKey: .tstamp)

        exerciseId = try c.decodeIfPresent(Int.self, forKey: .exerciseId)
        status = try c.decode(String.self, forKey: .status)
        instructor = try c.decodeIfPresent(Int.self, forKey: .instructor)

        notes = try c.decodeIfPresent(String.self, forKey: .notes)
        start = try c.decodeIfPresent(String.self, forKey: .start)
        stop = try c.decodeIfPresent(String.self, forKey: .stop)
        moduleId = try c.decodeIfPresent(Int.self, forKey: .moduleId)
        dateCompleted = try c.decodeIfPresent(Int.self, forKey: .dateCompleted)

        // Titel tolerant
        if let t = try c.decodeIfPresent(String.self, forKey: .exerciseTitle), !t.isEmpty {
            title = t
        } else if let t = try c.decodeIfPresent(String.self, forKey: .title), !t.isEmpty {
            title = t
        } else if let t = try c.decodeIfPresent(String.self, forKey: .name), !t.isEmpty {
            title = t
        } else {
            title = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)

        try c.encode(id, forKey: .id)
        try c.encodeIfPresent(published, forKey: .published)
        try c.encodeIfPresent(pid, forKey: .pid)
        try c.encodeIfPresent(sorting, forKey: .sorting)
        try c.encodeIfPresent(tstamp, forKey: .tstamp)

        try c.encodeIfPresent(exerciseId, forKey: .exerciseId)
        try c.encodeIfPresent(title, forKey: .exerciseTitle)
        try c.encode(status, forKey: .status)
        try c.encodeIfPresent(instructor, forKey: .instructor)
        try c.encodeIfPresent(notes, forKey: .notes)
        try c.encodeIfPresent(start, forKey: .start)
        try c.encodeIfPresent(stop, forKey: .stop)
        try c.encodeIfPresent(moduleId, forKey: .moduleId)
        try c.encodeIfPresent(dateCompleted, forKey: .dateCompleted)
    }

    var dateCompletedDate: Date? {
        guard let ts = dateCompleted else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(ts))
    }
}
