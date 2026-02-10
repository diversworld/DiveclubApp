//
//  MyCoursesView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import Foundation
import Combine

@MainActor
final class TankCheckListViewModel: ObservableObject {

    @Published var proposals: [TankCheckProposalDTO] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            proposals = try await APIClient.shared.getTankCheckProposals()
                .filter { $0.published ?? true }
                .sorted { ($0.proposalDate ?? .distantFuture) < ($1.proposalDate ?? .distantFuture) }
        } catch {
            if case APIError.badStatus(let code, _) = error, code == 401 {
                errorMessage = "Bitte neu einloggen."
            } else {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
    }
}

@MainActor
final class TankCheckBookingViewModel: ObservableObject {

    @Published var isSubmitting = false
    @Published var error: String?
    @Published var successMessage: String?

    func submit(_ payload: TankCheckBookingPayload) async -> Bool {
        isSubmitting = true
        error = nil
        successMessage = nil
        defer { isSubmitting = false }

        do {
            let resp = try await APIClient.shared.bookTankCheck(payload)
            successMessage = resp.message ?? "Buchung erfolgreich."
            return true
        } catch {
            self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return false
        }
    }
}
