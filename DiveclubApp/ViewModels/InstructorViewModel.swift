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

    @Published var enrollments: [InstructorEnrollment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // optional: nur laden, wenn Instructor
            guard AuthManager.shared.currentMember?.isInstructor == true else {
                enrollments = []
                return
            }

            let result: [InstructorEnrollment] = try await APIClient.shared.request("progress/instructor")
            enrollments = result
        } catch {
            errorMessage = error.localizedDescription
            enrollments = []
        }
    }
}
