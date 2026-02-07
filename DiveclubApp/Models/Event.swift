//
//  Event.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import Foundation

struct Event: Identifiable, Codable {
    let id: Int
    let published: Bool
    let title: String
    let courseId: Int
    let dateStart: TimeInterval
    let dateEnd: TimeInterval?
    let instructor: Int?
    let maxParticipants: Int?
    let price: String?
    let description: String?
    let location: String?
}

extension Event {
    
    var startDate: Date {
        Date(timeIntervalSince1970: dateStart)
    }
    
    var endDate: Date? {
        guard let dateEnd else { return nil }
        return Date(timeIntervalSince1970: dateEnd)
    }
    
    var formattedStartDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: startDate)
    }
}
