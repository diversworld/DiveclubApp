//
//  StudentProgress.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 08.02.26.
//


import Foundation

// MARK: - Generic helper (works with any CodingKeys)

private func decodeInt<K: CodingKey>(_ c: KeyedDecodingContainer<K>, forKey key: K) -> Int? {
    if let v = try? c.decodeIfPresent(Int.self, forKey: key) { return v }
    if let s = try? c.decodeIfPresent(String.self, forKey: key) { return Int(s) }
    return nil
}

// MARK: - StudentEnrollmentProgress

struct StudentEnrollmentProgress: Identifiable, Decodable, Equatable {

    let id: Int
    let enrollmentId: Int?
    let enrollment: EnrollmentInfo?
    let course: CourseInfo
    let exercises: [StudentExercise]

    /// ✅ Event-ID kann entweder top-level oder in enrollment stecken.
    var eventId: Int? {
        if let top = _eventId { return top }
        return enrollment?.eventId
    }

    private let _eventId: Int?

    enum CodingKeys: String, CodingKey {
        case id

        case enrollmentId
        case enrollment_id

        case enrollment
        case course
        case exercises

        case eventId
        case event_id
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id = try c.decode(Int.self, forKey: .id)

        enrollmentId =
            decodeInt(c, forKey: .enrollmentId)
            ?? decodeInt(c, forKey: .enrollment_id)

        enrollment = try c.decodeIfPresent(EnrollmentInfo.self, forKey: .enrollment)
        course = try c.decode(CourseInfo.self, forKey: .course)
        exercises = try c.decodeIfPresent([StudentExercise].self, forKey: .exercises) ?? []

        _eventId =
            decodeInt(c, forKey: .event_id)
            ?? decodeInt(c, forKey: .eventId)
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

    let status: String?
    let courseId: Int?

    enum CodingKeys: String, CodingKey {
        case id

        case eventId
        case event_id

        case status

        case courseId
        case course_id
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id = try c.decode(Int.self, forKey: .id)

        eventId =
            decodeInt(c, forKey: .eventId)
            ?? decodeInt(c, forKey: .event_id)

        status = try c.decodeIfPresent(String.self, forKey: .status)

        courseId =
            decodeInt(c, forKey: .courseId)
            ?? decodeInt(c, forKey: .course_id)
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
        case exercise_id

        case status

        case dateCompleted
        case date_completed

        case title
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id = try c.decode(Int.self, forKey: .id)

        exerciseId =
            decodeInt(c, forKey: .exerciseId)
            ?? decodeInt(c, forKey: .exercise_id)

        status = (try? c.decode(String.self, forKey: .status)) ?? ""

        dateCompleted =
            decodeInt(c, forKey: .dateCompleted)
            ?? decodeInt(c, forKey: .date_completed)

        title = try c.decodeIfPresent(String.self, forKey: .title)
    }
}
