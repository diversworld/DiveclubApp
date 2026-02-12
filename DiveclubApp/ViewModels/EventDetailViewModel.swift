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
    private var cancellables = Set<AnyCancellable>()

    init() {
        // ✅ Immer wenn sich Enrollments ändern: isAlreadyBooked neu berechnen
        enrollmentStore.$enrollments
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.recomputeAlreadyBooked()
            }
            .store(in: &cancellables)
    }

    // MARK: - Load Event

    func loadEvent(id: Int) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let loadedEvent: Event = try await APIClient.shared.request("/events/\(id)")
            self.event = loadedEvent

            // ✅ Erstmal anhand der aktuell vorhandenen Daten entscheiden
            recomputeAlreadyBooked()

            // ✅ Dann Store aktualisieren (kann async/parallel passieren)
            await enrollmentStore.load()

            // ✅ Danach nochmal sicher neu berechnen
            recomputeAlreadyBooked()

        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    // MARK: - Anmeldung

    func enroll() async {
        guard let event else { return }

        // ✅ Immer frisch prüfen (nicht nur auf isAlreadyBooked verlassen)
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

            try await APIClient.shared.requestWithoutResponse(
                "/courses/enroll",
                method: "POST",
                body: request
            )

            // 🔄 Store synchronisieren
            await enrollmentStore.load()

            // ✅ UI-Status sofort korrekt setzen
            isAlreadyBooked = true
            bookingSuccess = true

            // 🔄 Event neu laden (Teilnehmerzahlen etc.)
            await loadEvent(id: event.id)

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

    // MARK: - Helpers

    private func recomputeAlreadyBooked() {
        guard let id = event?.id else {
            isAlreadyBooked = false
            return
        }
        isAlreadyBooked = enrollmentStore.isEnrolled(eventId: id)
    }
}
