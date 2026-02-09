//
//  EventsViewModel.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import Foundation
import Combine

@MainActor
final class EventsViewModel: ObservableObject {
    @Published var events: [EventDTO] = []
    @Published var tankChecks: [TankCheckProposalDTO] = []
    @Published var isLoading = false
    @Published var error: String?

    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            async let eventsTask = APIClient.shared.getEvents()
            async let tankChecksTask = APIClient.shared.getTankCheckProposals()

            events = try await eventsTask

            tankChecks = try await tankChecksTask
                .filter { $0.published ?? true }
                .sorted { ($0.proposalDate ?? .distantFuture) < ($1.proposalDate ?? .distantFuture) }

        } catch {
            self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
