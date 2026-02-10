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
            // Spezialfall (bei dir kam das früher beim Instructor): "no student profile found"
            let msg = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            if msg.lowercased().contains("no student profile") {
                isNotAStudentProfile = true
                enrollments = []
                return
            }

            errorMessage = msg
            enrollments = []
        }
    }
}

