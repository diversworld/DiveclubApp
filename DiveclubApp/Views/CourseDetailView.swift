//
//  CourseDetailView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 08.02.26.
//


import SwiftUI

struct CourseDetailView: View {

    private enum Tab: String, CaseIterable, Identifiable {
        case progress = "Fortschritt"
        case schedule = "Plan"
        var id: String { rawValue }
    }

    @StateObject private var vm: CourseDetailViewModel
    @State private var tab: Tab = .progress

    init(enrollment: StudentEnrollmentProgress) {
        _vm = StateObject(wrappedValue: CourseDetailViewModel(enrollment: enrollment))
    }

    var body: some View {
        List {

            Section {
                headerView

                Picker("Ansicht", selection: $tab) {
                    ForEach(Tab.allCases) { t in
                        Text(t.rawValue).tag(t)
                    }
                }
                .pickerStyle(.segmented)
            }

            switch tab {
            case .schedule:
                scheduleSection
            case .progress:
                progressSection
            }
        }
        .navigationTitle("Kursdetails")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await vm.loadHeader()
            if tab == .schedule { await vm.loadScheduleIfNeeded() }
        }
        .onChange(of: tab) { _, newValue in
            if newValue == .schedule {
                Task { await vm.loadScheduleIfNeeded() }
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {

            Text(vm.enrollment.course.title.decodedEntities)
                .font(.headline)

            if vm.isLoadingHeader {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Lade Event …").foregroundStyle(.secondary)
                }
            } else if let ev = vm.eventDetail {

                Text(ev.title.decodedEntities)
                    .foregroundStyle(.secondary)

                if let loc = ev.location, !loc.isEmpty {
                    Text(loc.decodedEntities)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let start = ev.dateStart {
                    Text("Beginn: \(Self.formatDateTime(start))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let end = ev.dateEnd {
                    Text("Ende: \(Self.formatDateTime(end))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

            } else {
                if let eventId = vm.enrollment.eventId {
                    Text("Event #\(eventId)")
                        .foregroundStyle(.secondary)
                }
            }

            // ✅ Kursbeschreibung: erst kurz, dann aufklappbar
            if let desc = vm.enrollment.course.description, !desc.isEmpty {
                ExpandableHTMLText(html: desc, textStyle: .footnote, collapsedLineLimit: 6)
                    .padding(.top, 2)
            }

            ProgressView(value: vm.enrollment.progressValue)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Fortschritt

    private var progressSection: some View {
        Section("Übungen") {
            if vm.enrollment.exercises.isEmpty {
                Text("Keine Übungen vorhanden.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(vm.enrollment.exercises) { ex in
                    VStack(alignment: .leading, spacing: 6) {

                        Text((ex.title ?? fallbackExerciseTitle(ex)).decodedEntities)
                            .font(.headline)

                        HStack {
                            Text("Status: \(ex.status)")
                                .foregroundStyle(.secondary)

                            Spacer()

                            if let ts = ex.dateCompleted {
                                Text(Self.formatDate(ts))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .font(.footnote)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func fallbackExerciseTitle(_ ex: StudentExercise) -> String {
        if let id = ex.exerciseId { return "Übung \(id)" }
        return "Übung #\(ex.id)"
    }

    // MARK: - Plan

    private var scheduleSection: some View {
        Section("Terminplan") {
            if vm.isLoadingSchedule {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Lade Plan …").foregroundStyle(.secondary)
                }

            } else if let err = vm.scheduleError {
                Text(err).foregroundStyle(.red)

            } else if vm.schedule.isEmpty {
                Text("Kein Terminplan vorhanden.")
                    .foregroundStyle(.secondary)

            } else {
                ForEach(vm.schedule) { item in
                    VStack(alignment: .leading, spacing: 6) {

                        Text(item.moduleTitle.decodedEntities)
                            .font(.headline)

                        HStack(alignment: .firstTextBaseline) {
                            if let loc = item.location, !loc.isEmpty {
                                Text(loc.decodedEntities)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text(Self.formatDateTime(item.plannedAt))
                                .foregroundStyle(.secondary)
                        }
                        .font(.footnote)

                        if let notes = item.notes, !notes.isEmpty {
                            Text(notes.htmlToPlainText)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Date formatting

    private static func formatDate(_ unix: Int) -> String {
        let d = Date(timeIntervalSince1970: TimeInterval(unix))
        return formatDate(d)
    }

    private static func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: date)
    }

    private static func formatDateTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }
}
