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

    /// Backend kann String ODER Zahl liefern
    let dateOfBirth: TimeInterval?

    /// Backend liefert z.B. "instructor"
    let role: String?

    // MARK: - Computed

    var fullName: String {
        "\(firstname ?? "") \(lastname ?? "")"
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isInstructor: Bool {
        (role ?? "").lowercased() == "instructor"
    }

    var birthDate: Date? {
        guard let dateOfBirth else { return nil }
        return Date(timeIntervalSince1970: dateOfBirth)
    }

    var formattedBirthDate: String? {
        guard let birthDate else { return nil }
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateStyle = .medium
        return formatter.string(from: birthDate)
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id, username, firstname, lastname, email
        case street, postal, city, phone, mobile
        case dateOfBirth
        case role
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id = try c.decode(Int.self, forKey: .id)
        username = try c.decode(String.self, forKey: .username)

        firstname = try c.decodeIfPresent(String.self, forKey: .firstname)
        lastname  = try c.decodeIfPresent(String.self, forKey: .lastname)
        email     = try c.decodeIfPresent(String.self, forKey: .email)

        street = try c.decodeIfPresent(String.self, forKey: .street)
        postal = try c.decodeIfPresent(String.self, forKey: .postal)
        city   = try c.decodeIfPresent(String.self, forKey: .city)
        phone  = try c.decodeIfPresent(String.self, forKey: .phone)
        mobile = try c.decodeIfPresent(String.self, forKey: .mobile)

        role = try c.decodeIfPresent(String.self, forKey: .role)

        // dateOfBirth: kann Int/Double oder String sein
        if let ts = try? c.decode(TimeInterval.self, forKey: .dateOfBirth) {
            dateOfBirth = ts
        } else if let str = try? c.decode(String.self, forKey: .dateOfBirth),
                  let ts = TimeInterval(str) {
            dateOfBirth = ts
        } else {
            dateOfBirth = nil
        }
    }
}
