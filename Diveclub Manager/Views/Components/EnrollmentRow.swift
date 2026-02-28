//
//  EnrollmentRow.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 08.02.26.
//

import SwiftUI

struct EnrollmentRow: View {
    
    let enrollment: Enrollment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            HStack {
                Text(enrollment.title)
                    .font(.headline)
                
                Spacer()
                
                statusBadge
            }
            
            if let date = enrollment.formattedDate {
                Text(date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // 📊 Fortschritt bei active
            if enrollment.isActive {
                ProgressView(value: enrollment.progressValue)
                    .tint(.green)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: Badge
    
    private var statusBadge: some View {
        Text(enrollment.statusLabel)
            .font(.body)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(enrollment.statusColor.opacity(0.15))
            .foregroundStyle(enrollment.statusColor)
            .clipShape(Capsule())
    }
}

extension Enrollment {
    var isRegistered: Bool { reservationStatus == "registered" }
    var isActive: Bool { reservationStatus == "active" }
    var isCompleted: Bool { reservationStatus == "completed" }
    var isRejected: Bool { reservationStatus == "dropped" || reservationStatus == "rejected" }
}
