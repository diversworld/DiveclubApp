//
//  ScubaTank.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 09.02.26.
//

import Foundation

struct ScubaTank: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var nickname: String
    var serialNumber: String
    var volumeLiters: Int
    var workingPressureBar: Int
}
