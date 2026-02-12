//
//  CourseDetailViewModel.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 08.02.26.
//

import Foundation
import Combine

@MainActor
final class CourseDetailViewModel: ObservableObject {

    @Published var enrollment: StudentEnrollmentProgress

    // Event-Header-Infos
    @Published var eventDetail: EventDetail?
    @Published var isLoadingHeader = false
    @Published var headerError: String?

    // Schedule
    @Published var schedule: [EventScheduleItem] = []
    @Published var isLoadingSchedule = false
    @Published var scheduleError: String?

    init(enrollment: StudentEnrollmentProgress) {
        self.enrollment = enrollment
    }

    /// Lädt Event-Details für Header
    func loadHeader() async {
        guard !isLoadingHeader else { return }

        await MainActor.run {
            headerError = nil
            isLoadingHeader = true
        }
        defer {
            Task { @MainActor in
                self.isLoadingHeader = false
            }
        }

        guard let eventId = enrollment.eventId else {
            await MainActor.run {
                self.headerError = "Kein event_id vorhanden."
                self.eventDetail = nil
            }
            return
        }

        do {
            let e: EventDetail = try await APIClient.shared.request("/events/\(eventId)")
            await MainActor.run {
                self.eventDetail = e
            }
        } catch {
            await MainActor.run {
                self.headerError = Self.describe(error)
                self.eventDetail = nil
            }
        }
    }


    /// Lädt Terminplan nur bei Bedarf
    func loadScheduleIfNeeded() async {
        guard schedule.isEmpty else { return }

        guard let eventId = enrollment.eventId else {
            scheduleError = "Kein event_id vorhanden."
            return
        }

        isLoadingSchedule = true
        scheduleError = nil
        defer { isLoadingSchedule = false }

        do {
            let result: [EventScheduleItem] = try await APIClient.shared.request("/events/\(eventId)/schedule")
            schedule = result
        } catch {
            scheduleError = Self.describe(error)
            schedule = []
        }
    }

    private static func describe(_ error: Error) -> String {
        if case APIError.badStatus(let code, let body) = error {
            return "Serverfehler \(code): \(body ?? "")"
        }
        return (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
