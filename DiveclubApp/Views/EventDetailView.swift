//
//  EventDetailView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import SwiftUI

struct EventDetailView: View {

    let eventId: Int
    @StateObject private var vm = EventDetailViewModel()

    @State private var showSuccessAlert = false

    var body: some View {
        SwiftUI.Group {
            if vm.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else if let err = vm.errorMessage {
                ContentUnavailableView("Fehler", systemImage: "exclamationmark.triangle", description: Text(err))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else if let event = vm.event {
                SwiftUI.List {
                    SwiftUI.Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(event.title.decodedEntities)
                                .font(.headline)

                            if let start = event.dateStart {
                                Text("Beginn: \(formatDateTime(start))")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }

                            if let end = event.dateEnd {
                                Text("Ende: \(formatDateTime(end))")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }

                            if let loc = event.location, !loc.isEmpty {
                                Text(loc.decodedEntities)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 6)
                    }

                    if let desc = event.description, !desc.isEmpty {
                        SwiftUI.Section("Beschreibung") {
                            HTMLTextView(html: desc, textStyle: .body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    SwiftUI.Section {
                        if vm.isAlreadyBooked {
                            Label("Du bist bereits angemeldet.", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.secondary)

                        } else if vm.isSubmitting {
                            HStack(spacing: 10) {
                                ProgressView()
                                Text("Sende Anmeldung …").foregroundStyle(.secondary)
                            }

                        } else {
                            Button {
                                Task { await vm.enroll() }
                            } label: {
                                Label(buttonTitle(event: event), systemImage: "checkmark.seal")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(vm.isSubmitting || vm.isAlreadyBooked || vm.isFull)
                        }

                        if vm.isFull && !vm.isAlreadyBooked {
                            Text("Dieser Termin ist aktuell voll.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onChange(of: vm.bookingSuccess) { _, newValue in
                    if newValue { showSuccessAlert = true }
                }
                .alert("Erfolg", isPresented: $showSuccessAlert) {
                    Button("OK") {
                        vm.bookingSuccess = false
                        showSuccessAlert = false
                    }
                } message: {
                    Text("Du wurdest erfolgreich angemeldet.")
                }

            } else {
                ContentUnavailableView(
                    "Kein Event",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("Event konnte nicht geladen werden.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Event")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await vm.loadEvent(id: eventId)
        }
    }

    private func buttonTitle(event: Event) -> String {
        vm.isFull ? "Ausgebucht" : "Anmelden"
    }

    private func formatDateTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }
}
