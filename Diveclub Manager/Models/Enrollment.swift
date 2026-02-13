//
//  Enrollment.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

//
//  Enrollment.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import Foundation
import SwiftUI

struct Enrollment: Decodable, Identifiable, Equatable {

    let id: Int
    let title: String

    let eventId: Int?
    let reservationStatus: String
    let dateStart: Int?
    let courseId: Int?

    // optional
    let progress: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case eventId = "event_id"

        case reservationStatus = "reservation_status"
        case reservationStatusAlt = "reservationStatus" // tolerant

        case dateStart
        case courseId = "course_id"

        case progress
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id = try c.decode(Int.self, forKey: .id)
        title = (try? c.decode(String.self, forKey: .title)) ?? "Kurs"

        eventId = try? c.decodeIfPresent(Int.self, forKey: .eventId)
        dateStart = try? c.decodeIfPresent(Int.self, forKey: .dateStart)
        courseId = try? c.decodeIfPresent(Int.self, forKey: .courseId)
        progress = try? c.decodeIfPresent(Double.self, forKey: .progress)

        // ✅ reservation_status robust
        if let s = try? c.decode(String.self, forKey: .reservationStatus) {
            reservationStatus = s
        } else if let s = try? c.decode(String.self, forKey: .reservationStatusAlt) {
            reservationStatus = s
        } else {
            // Notfalls: Default, damit es nicht crasht
            reservationStatus = "unknown"
        }
    }

    // MARK: Date

    var date: Date? {
        guard let dateStart, dateStart > 0 else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(dateStart))
    }

    var formattedDate: String? {
        guard let date else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    // MARK: Status Logic (UI)

    var progressValue: Double { progress ?? 0.0 }

    var statusLabel: String {
        switch reservationStatus.lowercased() {
        case "registered": return "Angemeldet"
        case "active": return "Läuft"
        case "completed": return "Abgeschlossen"
        case "waitlist": return "Warteliste"
        case "dropped", "rejected": return "Abgelehnt"
        default: return reservationStatus.capitalized
        }
    }

    var statusColor: Color {
        switch reservationStatus.lowercased() {
        case "registered": return .blue
        case "active": return .green
        case "completed": return .gray
        case "waitlist": return .orange
        case "dropped", "rejected": return .red
        default: return .primary
        }
    }
}

