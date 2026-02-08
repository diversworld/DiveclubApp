//
//  InstructorEnrollment.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 08.02.26.
//

import Foundation

struct InstructorEnrollment: Codable, Identifiable {
    
    var id: Int { enrollment_id }
    
    let enrollment_id: Int
    let course_title: String
    let event_title: String
    let student: InstructorStudent
    let status: String
    let exercises: [InstructorExercise]
    
    // MARK: Computed
    
    var studentName: String {
        "\(student.firstname ?? "") \(student.lastname ?? "")"
    }
    
    var courseTitle: String {
        course_title
    }
    
    var isActive: Bool {
        status == "active"
    }
    
    var isPending: Bool {
        status == "registered"
    }
    
    var progressValue: Double {
        guard !exercises.isEmpty else { return 0 }
        let completed = exercises.filter { $0.status == "ok" }.count
        return Double(completed) / Double(exercises.count)
    }
    
    var statusColor: String {
        switch status {
        case "active": return "green"
        case "completed": return "blue"
        case "registered": return "orange"
        default: return "gray"
        }
    }
}
