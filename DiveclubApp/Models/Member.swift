//
//  Member.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

//
//  Member.swift
//  DiveclubApp
//

import Foundation

struct Member: Codable, Identifiable {
    
    let id: Int
    let username: String
    let firstname: String?
    let lastname: String?
    let email: String?
    let street: String?
    let postal: String?
    let city: String?
    let phone: String?
    let mobile: String?
    let dateOfBirth: TimeInterval?
    let role: String?
    
    var fullName: String {
        "\(firstname ?? "") \(lastname ?? "")"
            .trimmingCharacters(in: .whitespaces)
    }
    
    var isInstructor: Bool {
        role == "instructor"
    }
    var birthDate: Date? {
        guard let dateOfBirth else { return nil }
        return Date(timeIntervalSince1970: dateOfBirth)
    }
    
    var formattedBirthDate: String? {
        guard let birthDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: birthDate)
    }
}
