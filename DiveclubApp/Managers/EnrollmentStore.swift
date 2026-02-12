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

    /// Badge: Anzahl aktiver Kurse
    var activeCount: Int {
        enrollments.filter { $0.reservationStatus.lowercased() == "active" }.count
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
                errorMessage = error.localizedDescription
                enrollments = []
            }
        }

        /// Alt-Kompatibilität
        func load() async { await refresh() }

    func clear() {
        enrollments = []
        errorMessage = nil
        isLoading = false
    }

    func isEnrolled(eventId: Int) -> Bool {
        enrollments.contains(where: { $0.eventId == eventId })
    }


    func isEnrolled(enrollmentId: Int) -> Bool {
        enrollments.contains(where: { $0.id == enrollmentId })
    }
}

