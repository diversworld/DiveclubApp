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
                ProgressView("Lade TÜV-Angebote …")
            }

            if let err = vm.error {
                Text(err).foregroundStyle(.red)
            }

            ForEach(vm.proposals) { p in
                NavigationLink {
                    TankCheckDetailView(proposalId: p.id)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(p.title ?? "TÜV-Angebot")
                            .font(.headline)

                        if let d = p.proposalDate {
                            Text(d, style: .date)
                        } else {
                            Text("Datum folgt").foregroundStyle(.secondary)
                        }

                        if let v = p.vendorName, !v.isEmpty {
                            Text(v).font(.footnote).foregroundStyle(.secondary)
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
