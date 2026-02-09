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
            let result: [StudentEnrollmentProgress] = try await APIClient.shared.request("progress")
            enrollments = result
        } catch {
            enrollments = []

            // ✅ Backend liefert: HTTP 404: no student profile found
            if let net = error as? NetworkError {
                switch net {
                case .httpStatus(let code, let body):
                    if code == 404,
                       (body?.lowercased().contains("no student profile found") == true) {
                        isNotAStudentProfile = true
                        return
                    }
                default:
                    break
                }
            }

            errorMessage = error.localizedDescription
        }
    }
}
