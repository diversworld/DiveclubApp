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

    // Event-Header-Infos (Event-Titel/Ort/Zeiten)
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

    /// Lädt Event-Details für Header (Kursdaten kommen bereits aus /api/progress -> enrollment.course)
    func loadHeader() async {
        guard !isLoadingHeader else { return }

        headerError = nil
        isLoadingHeader = true
        defer { isLoadingHeader = false }

        guard let eventId = enrollment.eventId else {
            headerError = "Kein event_id vorhanden."
            eventDetail = nil
            return
        }

        do {
            let e: EventDetail = try await APIClient.shared.request("events/\(eventId)")
            eventDetail = e
        } catch {
            headerError = error.localizedDescription
            eventDetail = nil
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
            let result: [EventScheduleItem] = try await APIClient.shared.request("events/\(eventId)/schedule")
            schedule = result
        } catch {
            scheduleError = error.localizedDescription
            schedule = []
        }
    }
}

