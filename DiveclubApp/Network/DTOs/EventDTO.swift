//
//  EventDTO.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 09.02.26.
//

import Foundation

struct EventDTO: Identifiable, Decodable, Equatable {
    let id: Int
    let title: String
    let startDate: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case startDate = "startDate"
    }
}
