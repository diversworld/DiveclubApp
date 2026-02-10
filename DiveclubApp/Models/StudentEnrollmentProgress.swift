//
//  StudentProgress.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 08.02.26.
//

import Foundation

struct StudentEnrollmentProgress: Identifiable, Decodable, Equatable {

    // Top-Level
    let id: Int
    let enrollmentId: Int?
    let enrollment: EnrollmentInfo?
    let course: CourseInfo
    let exercises: [StudentExercise]

    // ✅ Wichtig: wir liefern immer eine eventId zurück, wenn irgendwo vorhanden
    var eventId: Int? {
        // 1) falls später mal direkt am Top-Level geliefert wird (event_id)
        if let top = _eventId { return top }
        // 2) so kommt es bei dir aus /api/progress: enrollment.event_id
        return enrollment?.eventId
    }

    /// interner Storage für optionales Top-Level event_id
    private let _eventId: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case enrollmentId
        case enrollment
        case course
        case exercises
        case _eventId = "eventId"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id = try c.decode(Int.self, forKey: .id)

        // enrollment_id kann bei dir vorhanden sein
        enrollmentId = try c.decodeIfPresent(Int.self, forKey: .enrollmentId)

        enrollment = try c.decodeIfPresent(EnrollmentInfo.self, forKey: .enrollment)

        course = try c.decode(CourseInfo.self, forKey: .course)
        exercises = try c.decodeIfPresent([StudentExercise].self, forKey: .exercises) ?? []

        // optionales Top-Level eventId (falls du es irgendwo lieferst)
        _eventId = try c.decodeIfPresent(Int.self, forKey: ._eventId)
    }
}

extension StudentEnrollmentProgress {
    /// 0.0 ... 1.0 (für ProgressView(value:))
    var progressValue: Double {
        guard !exercises.isEmpty else { return 0.0 }
        let done = exercises.filter { ex in
            let s = ex.status.lowercased()
            return s == "ok" || s == "passed" || s == "done"
        }.count
        return Double(done) / Double(exercises.count)
    }
}

// MARK: - Nested types

struct EnrollmentInfo: Decodable, Equatable {
    let id: Int
    let eventId: Int?

    // weitere Felder optional (wenn du sie brauchst)
    let status: String?
    let courseId: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case eventId
        case status
        case courseId
    }
}

struct CourseInfo: Decodable, Equatable {
    let id: Int
    let title: String
    let description: String?
}

struct StudentExercise: Identifiable, Decodable, Equatable {
    let id: Int
    let exerciseId: Int?
    let status: String
    let dateCompleted: Int?
    let title: String?

    enum CodingKeys: String, CodingKey {
        case id
        case exerciseId
        case status
        case dateCompleted
        case title
    }
}
