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

    @Published var eventDetail: EventDetail?
    @Published var isLoadingHeader = false
    @Published var headerError: String?

    @Published var schedule: [EventScheduleItem] = []
    @Published var isLoadingSchedule = false
    @Published var scheduleError: String?

    init(enrollment: StudentEnrollmentProgress) {
        self.enrollment = enrollment
    }

    func loadHeader() async {
        guard !isLoadingHeader else { return }

        // ✅ verhindert "Publishing changes from within view updates..."
        await Task.yield()

        headerError = nil
        isLoadingHeader = true
        defer { isLoadingHeader = false }

        guard let eventId = enrollment.eventId else {
            headerError = "Kein event_id vorhanden."
            eventDetail = nil
            return
        }

        do {
            let e: EventDetail = try await APIClient.shared.request("/events/\(eventId)")
            eventDetail = e
        } catch {
            headerError = Self.describe(error)
            eventDetail = nil
        }
    }

    func loadScheduleIfNeeded() async {
        guard schedule.isEmpty else { return }
        guard !isLoadingSchedule else { return }

        // ✅ verhindert "Publishing changes from within view updates..."
        await Task.yield()

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
