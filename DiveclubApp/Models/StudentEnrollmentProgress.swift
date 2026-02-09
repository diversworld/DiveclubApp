//
//  StudentProgress.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 08.02.26.
//

import Foundation

// MARK: - /api/progress

struct StudentEnrollmentProgress: Decodable, Identifiable {

    let enrollmentId: Int
    let enrollment: EnrollmentInfo
    let course: CourseInfo
    let exercises: [StudentExercise]

    var id: Int { enrollmentId }

    // Convenience für UI
    var courseTitle: String { course.title }
    var eventId: Int? { enrollment.eventId }
    var status: String { enrollment.status }

    var progressValue: Double {
        guard !exercises.isEmpty else { return 0 }
        let done = exercises.filter { $0.status == "ok" }.count
        return Double(done) / Double(exercises.count)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case enrollmentId = "enrollment_id"
        case enrollment
        case course
        case exercises
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        // ✅ tolerant: enrollment_id bevorzugen, sonst id
        if let v = try c.decodeIfPresent(Int.self, forKey: .enrollmentId) {
            self.enrollmentId = v
        } else if let v = try c.decodeIfPresent(Int.self, forKey: .id) {
            self.enrollmentId = v
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys.enrollmentId,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Missing enrollment id (expected enrollment_id or id)"
                )
            )
        }

        self.enrollment = try c.decode(EnrollmentInfo.self, forKey: .enrollment)
        self.course = try c.decode(CourseInfo.self, forKey: .course)
        self.exercises = (try c.decodeIfPresent([StudentExercise].self, forKey: .exercises)) ?? []
    }
}

struct EnrollmentInfo: Decodable {
    let id: Int
    let courseId: Int
    let eventId: Int?
    let status: String

    enum CodingKeys: String, CodingKey {
        case id
        case courseId = "courseId"
        case eventId = "eventId"
        case status
    }
}

struct CourseInfo: Decodable {
    let id: Int
    let title: String
    let description: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
    }
}

struct StudentExercise: Decodable, Identifiable {
    let id: Int
    let exerciseId: Int?
    let status: String
    let dateCompleted: Int?
    let title: String?

    enum CodingKeys: String, CodingKey {
        case id
        case exerciseId = "exerciseId"
        case status
        case dateCompleted
        case title
    }
}
