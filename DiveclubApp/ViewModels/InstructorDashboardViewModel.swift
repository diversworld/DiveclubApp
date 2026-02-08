//
//  InstructorDashboardViewModel.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 08.02.26.
//

import Foundation
import Combine

@MainActor
final class InstructorDashboardViewModel: ObservableObject {
    
    @Published var enrollments: [InstructorEnrollment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var timer: AnyCancellable?
    
    func load() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            enrollments = try await APIClient.shared.request("progress/instructor")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func startAutoRefresh() {
        timer = Timer.publish(every: 10, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { await self?.load() }
            }
    }
    
    func stopAutoRefresh() {
        timer?.cancel()
    }
    
    func approve(_ enrollment: InstructorEnrollment) async {
        try? await APIClient.shared.requestWithoutResponse(
            "instructor/approve/\(enrollment.id)",
            method: "PATCH",
            body: nil
        )
        await load()
    }
    
    func reject(_ enrollment: InstructorEnrollment) async {
        try? await APIClient.shared.requestWithoutResponse(
            "instructor/reject/\(enrollment.id)",
            method: "PATCH",
            body: nil
        )
        await load()
    }
}
