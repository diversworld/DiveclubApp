//
//  EventDetailViewModel.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import Foundation
import Combine

@MainActor
final class EventDetailViewModel: ObservableObject {
    
    @Published var event: Event?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSubmitting = false   // 👈 DAS MUSS DRIN SEIN
    
    func loadEvent(id: Int) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            event = try await APIClient.shared.request<Event>("events/\(id)")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func createReservation(for eventId: Int) async throws {
        
        let request = ReservationRequest(
            assetType: "event",
            items: [eventId],
            reservedFor: nil
        )
        
        let body = try JSONEncoder().encode(request)
        
        try await APIClient.shared.requestWithoutResponse(
            "reservations",
            method: "POST",
            body: body
        )
    }
}
