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
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    func load() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result: [EventDTO] = try await APIClient.shared.getEvents()
            self.events = result
        } catch {
            self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            self.events = []
        }
    }
}
