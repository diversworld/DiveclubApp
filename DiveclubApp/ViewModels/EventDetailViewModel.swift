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
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    @Published var bookingSuccess = false
    @Published var isAlreadyBooked = false
    
    private let enrollmentStore = EnrollmentStore.shared
    
    // MARK: - Load Event
    
    func loadEvent(id: Int) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let loadedEvent: Event =
                try await APIClient.shared.request("events/\(id)")
            
            self.event = loadedEvent
            
            // Prüfen ob User bereits angemeldet ist
            await EnrollmentStore.shared.load()

            isAlreadyBooked = EnrollmentStore.shared.isEnrolled(eventId: id)
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Anmeldung
    
    func enroll() async {
        guard let event else { return }

        guard !EnrollmentStore.shared.isEnrolled(eventId: event.id) else {
            isAlreadyBooked = true
            return
        }
        
        guard !isAlreadyBooked else {
                errorMessage = "Du bist bereits angemeldet."
                return
            }
        guard !isSubmitting else { return }
        
        guard let courseId = event.courseId else {
            errorMessage = "Keine Kurs-ID vorhanden."
            return
        }
        
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        
        do {
            let request = CourseEnrollmentRequest(
                course_id: courseId,
                event_id: event.id
            )
            
            let body = try JSONEncoder().encode(request)
            
            try await APIClient.shared.requestWithoutResponse(
                "courses/enroll",
                method: "POST",
                body: body
            )
            
            // 🔄 Global synchronisieren
            await enrollmentStore.load()
            
            // 🔄 Event neu laden (für Teilnehmerzahl)
            await loadEvent(id: event.id)
            
            bookingSuccess = true
            isAlreadyBooked = true
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Warteliste
    
    var isFull: Bool {
        guard let current = event?.currentParticipants,
              let max = event?.maxParticipants else { return false }
        return current >= max
    }
}
