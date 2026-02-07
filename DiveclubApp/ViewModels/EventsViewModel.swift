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

    @Published var events: [Event] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadEvents() async {
        isLoading = true
        defer { isLoading = false }

        do {
            events = try await APIClient.shared.request("events")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
