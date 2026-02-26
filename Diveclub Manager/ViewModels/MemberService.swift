//
//  MemberService.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 10.02.26.
//

import Foundation

@MainActor
final class MemberService {
    static let shared = MemberService()
    private init() {}

    struct Member: Identifiable, Equatable {
        let id: Int
        let fullName: String
    }

    /// ✅ throws, damit Call-Sites sauber Fehler behandeln können
    func loadMembers() async throws -> [Member] {
        let list: [MemberDTO] = try await APIClient.shared.request("members")
        return list.map { Member(id: $0.id, fullName: $0.fullName) }
    }
}
