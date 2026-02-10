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
        defer { isLoading = false }

        do {
            let loadedEvent: Event = try await APIClient.shared.request("/events/\(id)")
            self.event = loadedEvent

            // Prüfen ob User bereits angemeldet ist
            await enrollmentStore.load()
            isAlreadyBooked = enrollmentStore.isEnrolled(eventId: id)

        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    // MARK: - Anmeldung

    func enroll() async {
        guard let event else { return }

        // schon gebucht?
        if enrollmentStore.isEnrolled(eventId: event.id) {
            isAlreadyBooked = true
            return
        }
        if isAlreadyBooked {
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
        bookingSuccess = false
        defer { isSubmitting = false }

        do {
            let request = CourseEnrollmentRequest(courseId: courseId, eventId: event.id)

            // ✅ WICHTIG: Encodable direkt senden (nicht vorher JSONEncoder().encode)
            try await APIClient.shared.requestWithoutResponse(
                "/courses/enroll",
                method: "POST",
                body: request
            )

            // 🔄 Global synchronisieren
            await enrollmentStore.load()

            // 🔄 Event neu laden (für Teilnehmerzahl etc.)
            await loadEvent(id: event.id)

            bookingSuccess = true
            isAlreadyBooked = true

        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    // MARK: - Warteliste / Ausgebucht

    var isFull: Bool {
        guard let current = event?.currentParticipants,
              let max = event?.maxParticipants else { return false }
        return current >= max
    }
}
