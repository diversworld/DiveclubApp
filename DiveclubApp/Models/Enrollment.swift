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
    let eventId: Int?
    let reservationStatus: String
    let dateStart: TimeInterval?
    
    // Optional vom Backend (wenn progress geliefert wird)
    let progress: Double?
    
    // MARK: Date
    
    var date: Date? {
        guard let dateStart, dateStart > 0 else { return nil }
        return Date(timeIntervalSince1970: dateStart)
    }
    
    var formattedDate: String? {
        guard let date else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    // MARK: Status Logic
    
    var isRegistered: Bool {
        reservationStatus == "registered"
    }
    
    var isActive: Bool {
        reservationStatus == "active"
    }
    
    var isCompleted: Bool {
        reservationStatus == "completed"
    }
    
    var isRejected: Bool {
        reservationStatus == "dropped" ||
        reservationStatus == "rejected"
    }
    
    // MARK: UI Helpers
    
    var progressValue: Double {
        progress ?? 0.0
    }
    
    var statusLabel: String {
        switch reservationStatus {
        case "registered": return "Angemeldet"
        case "active": return "Läuft"
        case "completed": return "Abgeschlossen"
        case "waitlist": return "Warteliste"
        case "dropped": return "Abgelehnt"
        default: return reservationStatus.capitalized
        }
    }
    
    var statusColor: Color {
        switch reservationStatus {
        case "registered": return .blue
        case "active": return .green
        case "completed": return .gray
        case "waitlist": return .orange
        case "dropped": return .red
        default: return .primary
        }
    }
}
