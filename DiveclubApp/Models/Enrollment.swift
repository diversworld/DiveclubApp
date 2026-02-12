//
//  Enrollment.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//


import Foundation
import SwiftUI

struct Enrollment: Codable, Identifiable {

    let id: Int
    let title: String

    /// kommt aus event_id -> wird durch convertFromSnakeCase automatisch eventId
    let eventId: Int?

    /// kommt aus reservation_status -> wird durch convertFromSnakeCase automatisch reservationStatus
    let reservationStatus: String

    /// kommt aus dateStart (wie in deinem JSON) -> bleibt dateStart
    let dateStart: Int?

    /// optional (falls irgendwann geliefert)
    let progress: Double?

    // MARK: - Date

    var date: Date? {
        guard let dateStart, dateStart > 0 else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(dateStart))
    }

    var formattedDate: String? {
        guard let date else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    // MARK: - UI

    var progressValue: Double { progress ?? 0.0 }

    var statusLabel: String {
        switch reservationStatus {
        case "registered": return "Angemeldet"
        case "active": return "Läuft"
        case "completed": return "Abgeschlossen"
        case "waitlist": return "Warteliste"
        case "dropped", "rejected": return "Abgelehnt"
        default: return reservationStatus.capitalized
        }
    }

    var statusColor: Color {
        switch reservationStatus {
        case "registered": return .blue
        case "active": return .green
        case "completed": return .gray
        case "waitlist": return .orange
        case "dropped", "rejected": return .red
        default: return .primary
        }
    }
}
