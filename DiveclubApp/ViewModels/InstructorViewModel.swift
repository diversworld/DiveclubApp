//
//  InstructorViewModel.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 08.02.26.
//

import Foundation
import Combine

@MainActor
final class InstructorViewModel: ObservableObject {
    
    @Published var students: [InstructorStudent] = []
    @Published var errorMessage: String?
    
    private var timer: AnyCancellable?
    
    func startAutoRefresh() {
        timer = Timer.publish(every: 15, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                Task { await self.load() }
            }
    }
    
    func stopAutoRefresh() {
        timer?.cancel()
    }
    
    func load() async {
        do {
            print("Is Instructor:",
                  AuthManager.shared.currentMember?.isInstructor ?? false)

            students = try await APIClient.shared.request("progress/instructor")
            
            print("Loaded enrollments:", students.count)

        } catch {
            print("Instructor load error:", error)
            errorMessage = error.localizedDescription
        }
    }
}
