//
//  TankCheckListViewModel.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 12.02.26.
//

import Foundation
import Combine

@MainActor
final class TankCheckListViewModel: ObservableObject {

    @Published var proposals: [TankCheckProposalDTO] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let all: [TankCheckProposalDTO] = try await APIClient.shared.getTankCheckProposals()

            proposals = all
                .filter { $0.published }
                .sorted {
                    let a = $0.proposalDate ?? 0
                    let b = $1.proposalDate ?? 0
                    if a == b { return $0.id > $1.id }
                    return a > b
                }

        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            proposals = []
        }
    }
}
