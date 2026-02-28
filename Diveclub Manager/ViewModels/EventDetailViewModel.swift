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

    func loadEvent(id: Int) async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // ✅ erst Enrollments laden, damit "bereits angemeldet" stimmt
            await enrollmentStore.refresh()

            let loaded: Event = try await APIClient.shared.request("/events/\(id)")
            self.event = loaded

            if let courseId = loaded.courseId {
                self.isAlreadyBooked = enrollmentStore.isEnrolled(courseId: courseId) || enrollmentStore.isEnrolled(eventId: id)
            } else {
                self.isAlreadyBooked = enrollmentStore.isEnrolled(eventId: id)
            }

        } catch {
            self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func enroll() async {
        guard let currentEvent = self.event else { return }

        // ✅ stärkere Sperre: Course + Event
           if let courseId = currentEvent.courseId,
              enrollmentStore.isEnrolled(courseId: courseId) || enrollmentStore.isEnrolled(eventId: currentEvent.id) {
               isAlreadyBooked = true
               return
           }

        guard !isSubmitting else { return }

        guard let courseId = currentEvent.courseId else {
            errorMessage = "Keine Kurs-ID vorhanden."
            return
        }

        isSubmitting = true
        errorMessage = nil
        bookingSuccess = false
        defer { isSubmitting = false }

        do {
            let request = CourseEnrollmentRequest(courseId: courseId, eventId: currentEvent.id)

            try await APIClient.shared.requestWithoutResponse(
                "/courses/enroll",
                method: "POST",
                body: request
            )

            await enrollmentStore.refresh()

            isAlreadyBooked = true
            bookingSuccess = true

            // Event neu laden (Teilnehmerzahlen etc.)
            let updated: Event = try await APIClient.shared.request("/events/\(currentEvent.id)")
            self.event = updated

        } catch {
            // ✅ Wenn Server sagt "already enrolled" → UI sofort sperren statt nur Fehlermeldung
                if let apiError = error as? APIError {
                    switch apiError {
                    case .badStatus(let code, let body) where code == 400:
                        let b = (body ?? "").lowercased()
                        if b.contains("already") && b.contains("enrolled") {
                            await enrollmentStore.refresh()
                            isAlreadyBooked = true
                            errorMessage = nil
                            return
                        }
                        errorMessage = apiError.localizedDescription

                    default:
                        errorMessage = apiError.localizedDescription
                    }
                } else {
                    errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                }
        }
    }

    var isFull: Bool {
        guard let current = event?.currentParticipants,
              let max = event?.maxParticipants else { return false }
        return current >= max
    }
}
