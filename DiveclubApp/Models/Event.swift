//
//  Event.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import Foundation

struct Event: Codable, Identifiable {
    
    let id: Int
    let title: String
    let dateStart: TimeInterval
    let dateEnd: TimeInterval?
    let location: String?
    let price: String?
    let courseId: Int?
    let maxParticipants: Int?
    let currentParticipants: Int?
    
    var formattedStartDate: String {
        let date = Date(timeIntervalSince1970: dateStart)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
