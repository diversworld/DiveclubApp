//
//  LoginResponse.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import Foundation

struct LoginResponse: Codable {
    let success: Bool
    let member: Member
}

