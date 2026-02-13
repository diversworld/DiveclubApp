//
//  InstructorEnrollmentDetailViewModel.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 08.02.26.
//

import Foundation
import Combine

@MainActor
final class InstructorEnrollmentDetailViewModel: ObservableObject {

    @Published var enrollment: InstructorEnrollment
    @Published var exercises: [InstructorExercise]
    @Published var isSavingExerciseIDs: Set<Int> = []
    @Published var errorMessage: String?

    init(enrollment: InstructorEnrollment) {
        self.enrollment = enrollment
        self.exercises = enrollment.exercises
    }

    func updateExercise(
        exerciseId: Int,
        status: String,
        completedAt: Date?,
        notes: String?
    ) async {

        errorMessage = nil
        isSavingExerciseIDs.insert(exerciseId)
        defer { isSavingExerciseIDs.remove(exerciseId) }

        let timestamp: Int? = {
            if status == "pending" { return nil }
            if let completedAt { return Int(completedAt.timeIntervalSince1970) }
            return Int(Date().timeIntervalSince1970)
        }()

        let payload = UpdateExerciseRequest(
            status: status,
            dateCompleted: timestamp,
            notes: notes
        )

        do {
            let body = try JSONEncoder().encode(payload)

            // ✅ PATCH /api/progress/{exerciseId}
            try await APIClient.shared.requestWithoutResponse(
                "progress/\(exerciseId)",
                method: "PATCH",
                body: body
            )

            // ✅ Lokales UI aktualisieren
            if let idx = exercises.firstIndex(where: { $0.id == exerciseId }) {
                exercises[idx].status = status
                exercises[idx].dateCompleted = timestamp
                exercises[idx].notes = notes
            }

        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
