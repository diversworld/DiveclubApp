//
//  EnrollmentStore.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 08.02.26.
//

import Foundation
import Combine

@MainActor
final class EnrollmentStore: ObservableObject {
    static let shared = EnrollmentStore()

    @Published private(set) var enrollments: [Enrollment] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private init() {}

    /// Badge: zählt alle "relevanten" Anmeldungen (active + registered + waitlist etc.)
    /// Abgelehnte/Stornierte zählen nicht.
    var badgeCount: Int {
        enrollments.filter { e in
            let s = e.reservationStatus.lowercased()
            return s != "dropped" && s != "rejected" && s != "cancelled"
        }.count
    }

    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result: [Enrollment] = try await APIClient.shared.request("enrollments")
            enrollments = result
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            // wichtig: nicht alte Daten “vortäuschen”
            enrollments = []
        }
    }

    /// Alt: wird von bestehendem Code erwartet
    func load() async { await refresh() }

    func clear() {
        //enrollments = []
        //errorMessage = nil
        //isLoading = false
    }

    // ✅ NEU: Check per Course
    func isEnrolled(courseId: Int) -> Bool {
        enrollments.contains(where: { $0.courseId == courseId })
    }

    // Bestehendes Event-Check kannst du lassen
    func isEnrolled(eventId: Int) -> Bool {
        enrollments.contains(where: { $0.eventId == eventId })
    }
}
