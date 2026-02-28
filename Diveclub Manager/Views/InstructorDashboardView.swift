//
//  InstructorDashboardView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 08.02.26.
//

import SwiftUI

struct InstructorDashboardView: View {

    @StateObject private var vm = InstructorViewModel()

    private enum DashboardFilter: String, CaseIterable, Identifiable {
        case active = "Aktiv"
        case planned = "Geplant"
        var id: String { rawValue }
    }

    @State private var filter: DashboardFilter = .active

    private var shownEnrollments: [InstructorEnrollment] {
        switch filter {
        case .active:
            return vm.enrollments.filter { $0.isActive }
        case .planned:
            return vm.enrollments.filter { $0.isPending || $0.isRegistered }
        }
    }

    var body: some View {
        VStack(spacing: 0) {

            // ✅ Filter (stabil, nicht in Toolbar.principal)
            Picker("Filter", selection: $filter) {
                ForEach(DashboardFilter.allCases) { f in
                    Text(f.rawValue).tag(f)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)

            Group {
                if vm.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else if let error = vm.errorMessage {
                    ContentUnavailableView(
                        "Fehler",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else if shownEnrollments.isEmpty {
                    ContentUnavailableView(
                        filter == .active ? "Keine aktiven Kurse" : "Keine geplanten Kurse",
                        systemImage: "person.3",
                        description: Text(filter == .active
                                          ? "Aktuell keine aktiven Anmeldungen vorhanden."
                                          : "Aktuell keine geplanten Anmeldungen vorhanden.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(shownEnrollments) { enrollment in
                                NavigationLink {
                                    InstructorEnrollmentDetailView(enrollment: enrollment)
                                } label: {
                                    instructorCard(enrollment)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("Instructor")
        .task { await vm.load() }
        .refreshable { await vm.load() }
    }

    private func instructorCard(_ enrollment: InstructorEnrollment) -> some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {

                    Text(enrollment.studentName.isEmpty ? "Unbekannt" : enrollment.studentName)
                        .font(.headline)

                    // ✅ Entities decoden (benötigt String+Entities.swift)
                    Text(enrollment.eventTitle.decodedEntities)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(enrollment.courseTitle.decodedEntities)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                statusBadge(enrollment.status)
            }

            ProgressView(value: enrollment.progressValue)
                .tint(.green)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(radius: 4)
    }

    private func statusBadge(_ status: String) -> some View {
        Text(status.uppercased())
            .font(.body)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.thinMaterial)
            .clipShape(Capsule())
    }
}
