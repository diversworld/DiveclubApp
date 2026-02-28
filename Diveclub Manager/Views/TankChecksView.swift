//
//  TankChecksView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 09.02.26.
//


import SwiftUI

struct TankChecksView: View {

    @StateObject private var vm = TankCheckListViewModel()

    var body: some View {
        List {

            if vm.isLoading {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Lade TÜV-Angebote …")
                        .foregroundStyle(.secondary)
                }
            }

            if let err = vm.errorMessage {
                Text(err)
                    .foregroundStyle(.red)
            }

            Section("Geplante TÜV-Prüfungen") {
                if !vm.isLoading && vm.proposals.isEmpty {
                    Text("Aktuell kein TÜV-Termin geplant.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(vm.proposals) { p in
                        NavigationLink {
                            TankCheckDetailView(proposalId: p.id)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {

                                Text(p.title)
                                    .font(.headline)

                                if let unix = p.proposalDate, unix > 0 {
                                    Text(Date(timeIntervalSince1970: TimeInterval(unix)), style: .date)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("Datum folgt")
                                        .foregroundStyle(.secondary)
                                }

                                if let v = p.vendorName, !v.isEmpty {
                                    Text(v)
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .navigationTitle("TÜV-Prüfungen")
        .task { await vm.load() }
        .refreshable { await vm.load() }
    }
}
