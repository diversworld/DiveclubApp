//
//  InstructorDashboardView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 08.02.26.
//

import SwiftUI

struct InstructorDashboardView: View {
    
    @StateObject private var vm = InstructorDashboardViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                if vm.isLoading {
                    ProgressView()
                        .padding(.top, 40)
                }
                
                ForEach(vm.enrollments) { enrollment in
                    instructorCard(enrollment)
                }
            }
            .padding()
        }
        .navigationTitle("Instructor")
        .task {
            await vm.load()
            vm.startAutoRefresh()
        }
        .onDisappear {
            vm.stopAutoRefresh()
        }
    }
    
    // MARK: - Card
    
    private func instructorCard(_ enrollment: InstructorEnrollment) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            
            HStack {
                VStack(alignment: .leading) {
                    Text(enrollment.studentName)
                        .font(.headline)
                    
                    Text(enrollment.courseTitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                statusBadge(enrollment)
            }
            
            if enrollment.isActive {
                ProgressView(value: enrollment.progressValue)
                    .tint(.green)
            }
            
            if enrollment.isPending {
                HStack {
                    Button("Approve") {
                        Task { await vm.approve(enrollment) }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Reject", role: .destructive) {
                        Task { await vm.reject(enrollment) }
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(radius: 5)
    }
    
    // MARK: - Status Badge
    
    private func statusBadge(_ enrollment: InstructorEnrollment) -> some View {
        Text(enrollment.status.uppercased())
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(enrollment.statusColor).opacity(0.15))
            .foregroundStyle(Color(enrollment.statusColor))
            .clipShape(Capsule())
    }
}
