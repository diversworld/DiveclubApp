//
//  MyCoursesViewModel.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import Foundation
import Combine

@MainActor
final class MyCoursesViewModel: ObservableObject {

    @Published var enrollments: [StudentEnrollmentProgress] = []
    @Published var isLoading = false

    // UI-States
    @Published var errorMessage: String?
    @Published var isNotAStudentProfile = false

    func load() async {
        isLoading = true
        errorMessage = nil
        isNotAStudentProfile = false
        defer { isLoading = false }

        do {
            let result: [StudentEnrollmentProgress] = try await APIClient.shared.request("/progress")
            enrollments = result
        } catch {
            if case APIError.badStatus(let code, _) = error, code == 401 {
                self.errorMessage = "Bitte neu einloggen."
            } else {
                self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
    }
}
