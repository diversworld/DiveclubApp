//
//  EventDTO.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 09.02.26.
//

import Foundation

struct EventDTO: Identifiable, Decodable, Equatable {
    let id: Int
    let published: Bool?
    let sorting: Int?
    let tstamp: Int?

    let title: String
    let alias: String?

    let courseId: Int?

    /// Unix Timestamp (Sekunden)
    let dateStart: Int?
    let dateEnd: Int?

    let instructor: Int?
    let maxParticipants: Int?
    let price: String?
    let description: String?

    let location: String?
    let currentParticipants: Int?

    enum CodingKeys: String, CodingKey {
        case id, published, sorting, tstamp
        case title, alias
        case courseId = "course_id"
        case dateStart, dateEnd
        case instructor
        case maxParticipants = "max_participants"
        case price, description
        case location
        case currentParticipants
    }
}
