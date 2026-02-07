//
//  UpdateProfileRequest.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import Foundation

struct UpdateProfileRequest: Codable {
    let firstname: String?
    let lastname: String?
    let email: String?
    let street: String?
    let postal: String?
    let city: String?
    let phone: String?
    let mobile: String?
    let dateOfBirth: TimeInterval?
}
