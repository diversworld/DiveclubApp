//
//  TanksView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 09.02.26.
//

import SwiftUI
import Foundation
import Combine

@MainActor
final class TanksViewModel: ObservableObject {
    @Published var tanks: [Tank] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result: [Tank] = try await APIClient.shared.request("tanks")
            tanks = result
        } catch {
            errorMessage = error.localizedDescription
            tanks = []
        }
    }
}

struct TanksView: View {
    @StateObject private var vm = TanksViewModel()

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let err = vm.errorMessage {
                ContentUnavailableView("Fehler", systemImage: "exclamationmark.triangle", description: Text(err))
            } else if vm.tanks.isEmpty {
                ContentUnavailableView("Keine Flaschen", systemImage: "cylinder", description: Text("Aktuell sind keine Flaschen erfasst."))
            } else {
                List {
                    ForEach(vm.tanks) { t in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(t.displayTitle.decodedEntities).font(.headline)

                            if let last = t.lastInspection {
                                Text("Letzte Prüfung: \(Self.formatDate(last))")
                                    .foregroundStyle(.secondary)
                            }
                            if let next = t.nextInspection {
                                Text("Nächste fällig: \(Self.formatDate(next))")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Flaschen")
        .task { await vm.load() }
        .refreshable { await vm.load() }
    }

    private static func formatDate(_ unix: Int) -> String {
        let d = Date(timeIntervalSince1970: TimeInterval(unix))
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: d)
    }
}
