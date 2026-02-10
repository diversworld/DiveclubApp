//
//  TankChecksView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 09.02.26.
//

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
                                Text(p.title ?? "TÜV-Angebot")
                                    .font(.headline)

                                if let d = p.proposalDate {
                                    Text(d, style: .date)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("Datum folgt")
                                        .foregroundStyle(.secondary)
                                }

                                if let v = p.vendorName, !v.isEmpty {
                                    Text(v)
                                        .font(.footnote)
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
