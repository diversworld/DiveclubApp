//
//  EventDetail.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 08.02.26.
//

import Foundation


struct EventDetail: Decodable, Identifiable {
    let id: Int
    let title: String
    let description: String?
    let location: String?

    // Backend liefert Int-Timestamps (Unix seconds)
    let dateStart: Int?
    let dateEnd: Int?

    let courseId: Int?
    let currentParticipants: Int?
    let maxParticipants: Int?
    let price: String?

    enum CodingKeys: String, CodingKey {
        case id, title, description, location, price
        case dateStart, dateEnd
        case courseId = "course_id"
        case currentParticipants
        case maxParticipants = "max_participants"
    }
}
