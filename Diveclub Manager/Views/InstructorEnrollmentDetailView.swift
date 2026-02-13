//
//  InstructorEnrollmentDetailView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 08.02.26.
//


import SwiftUI

struct InstructorEnrollmentDetailView: View {

    @StateObject private var vm: InstructorEnrollmentDetailViewModel

    init(enrollment: InstructorEnrollment) {
        _vm = StateObject(wrappedValue: InstructorEnrollmentDetailViewModel(enrollment: enrollment))
    }

    var body: some View {
        List {

            Section("Kurs") {
                VStack(alignment: .leading, spacing: 6) {
                    Text(vm.enrollment.courseTitle.decodedEntities).font(.headline)
                    Text(vm.enrollment.eventTitle.decodedEntities).foregroundStyle(.secondary)
                    Text("Schüler: \(vm.enrollment.studentName)").foregroundStyle(.secondary)
                }
            }

            if let err = vm.errorMessage {
                Section {
                    Text(err).foregroundStyle(.red)
                }
            }

            Section("Übungen") {
                ForEach($vm.exercises) { $ex in
                    ExerciseRow(
                        exercise: $ex,
                        isSaving: vm.isSavingExerciseIDs.contains(ex.id),
                        onSave: { status, date, notes in
                            Task {
                                await vm.updateExercise(
                                    exerciseId: ex.id,
                                    status: status,
                                    completedAt: date,
                                    notes: notes
                                )
                            }
                        }
                    )
                }
            }
        }
        .navigationTitle("Übungen")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ExerciseRow: View {

    @Binding var exercise: InstructorExercise
    let isSaving: Bool
    let onSave: (_ status: String, _ completedAt: Date?, _ notes: String?) -> Void

    // ✅ stabiler lokaler State (nicht von Date() abhängig)
    @State private var completedDate: Date = Date()
    @State private var notesDraft: String = ""
    @State private var didEdit = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack {
                Text(displayTitle)
                    .font(.headline)

                Spacer()

                if isSaving { ProgressView() }
            }

            Picker("Status", selection: Binding(
                get: { exercise.status },
                set: { newValue in
                    exercise.status = newValue
                    didEdit = true

                    // Wenn von pending weg -> Datum setzen, falls noch keins existiert
                    if newValue != "pending" {
                        if exercise.dateCompleted == nil {
                            completedDate = Date()
                        }
                    } else {
                        // pending -> Datum zurücksetzen
                        exercise.dateCompleted = nil
                    }
                }
            )) {
                Text("pending").tag("pending")
                Text("ok").tag("ok")
                Text("repeat").tag("repeat")
                Text("failed").tag("failed")
            }
            .pickerStyle(.segmented)

            if exercise.status != "pending" {
                DatePicker(
                    "Abschlussdatum",
                    selection: Binding(
                        get: { completedDate },
                        set: { newDate in
                            completedDate = newDate
                            didEdit = true
                        }
                    ),
                    displayedComponents: [.date]
                )
            }

            TextField("Notizen (optional)", text: $notesDraft, axis: .vertical)
                .lineLimit(2...6)
                .onChange(of: notesDraft) { _, _ in didEdit = true }

            Button("Speichern") {
                let trimmed = notesDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                let notesToSend = trimmed.isEmpty ? nil : trimmed

                let dateToSend: Date? = (exercise.status == "pending") ? nil : completedDate

                onSave(exercise.status, dateToSend, notesToSend)
                didEdit = false
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSaving || !didEdit)
        }
        .padding(.vertical, 6)
        .onAppear {
            // ✅ initiale Werte einmalig setzen (stabil)
            notesDraft = exercise.notes ?? ""
            completedDate = exercise.dateCompletedDate ?? Date()
        }
        .onChange(of: exercise.dateCompleted) { _, newValue in
            // Wenn von außen aktualisiert (nach Save), sync
            if let ts = newValue {
                completedDate = Date(timeIntervalSince1970: TimeInterval(ts))
            }
        }
        .onChange(of: exercise.notes) { _, newValue in
            // Nach Save sync
            notesDraft = newValue ?? ""
        }
    }

    private var displayTitle: String {
        if let t = exercise.title?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty {
            return t.decodedEntities
        }
        if let exId = exercise.exerciseId {
            return "Übung \(exId)"
        }
        return "Übung #\(exercise.id)"
    }
}
