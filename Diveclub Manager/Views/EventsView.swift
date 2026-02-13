//
//  EventView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//


import SwiftUI

struct EventsView: View {

    @StateObject private var vm = EventsViewModel()

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else if let err = vm.errorMessage {
                ContentUnavailableView(
                    "Fehler",
                    systemImage: "exclamationmark.triangle",
                    description: Text(err)
                )

            } else if vm.events.isEmpty {
                ContentUnavailableView(
                    "Keine Events",
                    systemImage: "calendar",
                    description: Text("Aktuell keine Events vorhanden.")
                )

            } else {
                List(vm.events) { event in
                    NavigationLink {
                        // ⚠️ WICHTIG:
                        // Falls dein EventDetailView aktuell `Event` erwartet, ändere es
                        // auf `EventDTO` ODER erstelle einen Adapter.
                        EventDetailView(eventId: event.id)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(event.title.decodedEntities)
                                .font(.headline)

                            if let loc = event.location, !loc.isEmpty {
                                Text(loc.decodedEntities)
                                    .foregroundStyle(.secondary)
                            }

                            if let ts = event.dateStart {
                                Text(Self.formatDateTime(ts))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .task { await vm.load() }
        .refreshable { await vm.load() }
    }

    private static func formatDateTime(_ unix: Int) -> String {
        let d = Date(timeIntervalSince1970: TimeInterval(unix))
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: d)
    }
}
