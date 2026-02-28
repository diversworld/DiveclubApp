//
//  MyCoursesView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import SwiftUI

struct MyCoursesView: View {

    @StateObject private var vm = MyCoursesViewModel()

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)

            } else if vm.isNotAStudentProfile {
                ContentUnavailableView(
                    "Kein Schülerprofil",
                    systemImage: "person.crop.circle.badge.exclamationmark",
                    description: Text("Dieser Bereich zeigt den Kursfortschritt von Schülern. Für deinen Account wurde kein Schülerprofil gefunden.")
                )

            } else if let err = vm.errorMessage {
                ContentUnavailableView("Fehler", systemImage: "exclamationmark.triangle", description: Text(err))

            } else if vm.enrollments.isEmpty {
                ContentUnavailableView("Keine Kurse", systemImage: "person.3", description: Text("Aktuell keine Kurse vorhanden."))

            } else {
                List {
                    ForEach(vm.enrollments) { e in
                        NavigationLink {
                            CourseDetailView(enrollment: e)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(e.course.title.decodedEntities)
                                    .font(.headline)

                                if let eventId = e.eventId {
                                    Text("Event #\(eventId)")
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                }

                                if let desc = e.course.description, !desc.isEmpty {
                                    Text(desc.htmlSummary(maxChars: 300))
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(4)
                                }

                                ProgressView(value: e.progressValue)
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Meine Kurse")
        .task { await vm.load() }
        .refreshable { await vm.load() }
    }
}

