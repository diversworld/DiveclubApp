//
//  InstructorEnrollment.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 08.02.26.
//

import Foundation

struct InstructorEnrollment: Codable, Identifiable {
    let enrollmentId: Int
    let courseTitle: String
    let eventTitle: String
    let student: InstructorStudent
    let status: String
    let exercises: [InstructorExercise]

    var id: Int { enrollmentId }

    enum CodingKeys: String, CodingKey {
        case enrollmentId = "enrollmentId"
        case courseTitle = "courseTitle"
        case eventTitle = "eventTitle"
        case student
        case status
        case exercises
    }

    var isActive: Bool { status == "active" }
    var isRegistered: Bool { status == "registered" }
    var isPending: Bool { status == "pending" }

    var progressValue: Double {
        guard !exercises.isEmpty else { return 0 }
        let done = exercises.filter { $0.status == "ok" }.count
        return Double(done) / Double(exercises.count)
    }

    var studentName: String {
        "\(student.firstname ?? "") \(student.lastname ?? "")".trimmingCharacters(in: .whitespaces)
    }
}
