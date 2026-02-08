//
//  Member.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
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
    let isInstructor: Bool?
    
    // MARK: - Computed
    
    var fullName: String {
        "\(firstname ?? "") \(lastname ?? "")"
            .trimmingCharacters(in: .whitespaces)
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
    
    var instructor: Bool {
        isInstructor ?? false
    }
    
    // MARK: - Coding
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case firstname
        case lastname
        case email
        case street
        case postal
        case city
        case phone
        case mobile
        case dateOfBirth
        case isInstructor
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        firstname = try container.decodeIfPresent(String.self, forKey: .firstname)
        lastname = try container.decodeIfPresent(String.self, forKey: .lastname)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        street = try container.decodeIfPresent(String.self, forKey: .street)
        postal = try container.decodeIfPresent(String.self, forKey: .postal)
        city = try container.decodeIfPresent(String.self, forKey: .city)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        mobile = try container.decodeIfPresent(String.self, forKey: .mobile)
        
        // 🔥 DATE SAFE DECODING (String oder Int)
        if let timestamp = try? container.decode(TimeInterval.self, forKey: .dateOfBirth) {
            dateOfBirth = timestamp
        } else if let string = try? container.decode(String.self, forKey: .dateOfBirth),
                  let timestamp = TimeInterval(string) {
            dateOfBirth = timestamp
        } else {
            dateOfBirth = nil
        }
        
        isInstructor = try container.decodeIfPresent(Bool.self, forKey: .isInstructor)
    }
}
