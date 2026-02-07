//
//  ChangePasswordRequest.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import Foundation

struct ChangePasswordRequest: Codable {
    let currentPassword: String
    let newPassword: String
}
