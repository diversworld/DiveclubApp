//
//  EventView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import SwiftUI
import Combine

struct EventsView: View {
    @StateObject private var vm = EventsViewModel()

    var body: some View {
        List {
            if vm.isLoading {
                ProgressView("Lade Events …")
            }
            if let err = vm.error {
                Text(err).foregroundStyle(.red)
            }

            // Deine bestehenden Events
            Section("Events") {
                ForEach(vm.events) { e in
                    Text(e.title)
                }
            }

            // TÜV Section aus Tank-Checks
            Section("TÜV (geplante Prüfungen)") {
                if vm.tankChecks.isEmpty && !vm.isLoading {
                    Text("Aktuell kein TÜV-Termin geplant.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(vm.tankChecks) { p in
                        NavigationLink {
                            TankCheckDetailView(proposalId: p.id)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(p.title ?? "TÜV-Prüfung").font(.headline)
                                if let d = p.proposalDate {
                                    Text(d, style: .date)
                                } else {
                                    Text("Datum folgt").foregroundStyle(.secondary)
                                }
                                if let vendor = p.vendorName, !vendor.isEmpty {
                                    Text(vendor).font(.footnote).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Events")
        .task { await vm.load() }
        .refreshable { await vm.load() }
    }
}
