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
    @Published var error: String?
    @Published var isBusy: Bool = false

    func approveEnrollment(enrollmentId: Int) async {
        await patchEnrollment(path: "/instructor/approve/\(enrollmentId)")
    }

    func rejectEnrollment(enrollmentId: Int) async {
        await patchEnrollment(path: "/instructor/reject/\(enrollmentId)")
    }

    private func patchEnrollment(path: String) async {
        isBusy = true
        error = nil
        defer { isBusy = false }

        do {
            // KEIN body -> vermeidet "Generic parameter B could not be inferred"
            try await APIClient.shared.requestWithoutResponse(path, method: "PATCH")
        } catch {
            self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
