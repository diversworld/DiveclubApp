//
//  InstructorStudent.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 08.02.26.
//

import Foundation

struct InstructorStudent: Codable, Identifiable {
    
    let id: Int
    let firstname: String?
    let lastname: String?
    let email: String?
    let progress: Int?
    
    var fullName: String {
        "\(firstname ?? "") \(lastname ?? "")"
            .trimmingCharacters(in: .whitespaces)
    }
    
    var progressValue: Double {
        Double(progress ?? 0) / 100.0
    }
}
