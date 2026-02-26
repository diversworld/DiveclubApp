//
//  MemberDTO.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 10.02.26.
//

import Foundation

struct MemberDTO: Decodable, Identifiable, Equatable {

    // ✅ keyDecodingStrategy = convertFromSnakeCase macht aus "member_id" -> "memberId"
    let memberId: Int
    let firstName: String?
    let lastName: String?
    let displayName: String?

    var id: Int { memberId }

    enum CodingKeys: String, CodingKey {
        case memberId          // ✅ kommt nach convertFromSnakeCase aus JSON "member_id"
        case firstName = "vorname"
        case lastName  = "name"
        case displayName = "display_name"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        // memberId kann Int oder String sein
        if let v = try? c.decode(Int.self, forKey: .memberId) {
            memberId = v
        } else if let s = try? c.decode(String.self, forKey: .memberId), let v = Int(s) {
            memberId = v
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys.memberId,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "No value for memberId (from member_id)."
                )
            )
        }

        firstName = try? c.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try? c.decodeIfPresent(String.self, forKey: .lastName)
        displayName = try? c.decodeIfPresent(String.self, forKey: .displayName)
    }

    var fullName: String {
        if let displayName, !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return displayName
        }
        let f = (firstName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let l = (lastName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let combined = (f + " " + l).trimmingCharacters(in: .whitespacesAndNewlines)
        return combined.isEmpty ? "Mitglied #\(memberId)" : combined
    }
}
