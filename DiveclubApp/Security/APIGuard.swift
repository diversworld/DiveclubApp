//
//  APIGuard.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 08.02.26.
//

import Foundation

enum APIGuardError: LocalizedError {
    case forbidden
    var errorDescription: String? { "Zugriff nicht erlaubt." }
}

struct APIGuard {
    static func requireInstructor() throws {
        guard AuthManager.shared.isInstructor else {
            throw APIGuardError.forbidden
        }
    }
}
