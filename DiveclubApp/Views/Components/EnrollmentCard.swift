//
//  EnrollmentCard.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 08.02.26.
//

import SwiftUI

struct EnrollmentCard: View {
    
    let enrollment: Enrollment
    
    var body: some View {
        
        NavigationLink {
            EventDetailView(eventId: enrollment.eventId ?? 0)
        } label: {
            
            VStack(alignment: .leading, spacing: 14) {
                
                HStack(alignment: .top) {
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(enrollment.title)
                            .font(.headline)
                        
                        if let formattedDate = enrollment.formattedDate {
                            Label(formattedDate, systemImage: "calendar")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    statusBadge
                }
                
                Divider()
                
                HStack {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .strokeBorder(.white.opacity(0.2))
            )
            .shadow(color: .black.opacity(0.1),
                    radius: 12,
                    x: 0,
                    y: 8)
            .scaleEffect(1.0)
        }
        .buttonStyle(.plain)
        .opacity(enrollment.isRejected ? 0.6 : 1)
    }
    
    // MARK: - Status Badge
    
    private var statusBadge: some View {
        Text(statusText)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(statusColor.opacity(0.2))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch enrollment.reservationStatus {
        case "registered":
            return .green
        case "completed":
            return .blue
        case "rejected":
            return .gray
        default:
            return .orange
        }
    }
    
    private var statusText: String {
        switch enrollment.reservationStatus {
        case "registered":
            return "Angemeldet"
        case "completed":
            return "Abgeschlossen"
        case "rejected":
            return "Abgelehnt"
        default:
            return enrollment.reservationStatus.capitalized
        }
    }
}

