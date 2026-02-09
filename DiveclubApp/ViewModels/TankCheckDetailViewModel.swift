//
//  TankCheckDetailViewModel.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 09.02.26.
//

import Foundation
import Combine

@MainActor
final class TankCheckDetailViewModel: ObservableObject {
    @Published var detail: TankCheckProposalDetailDTO?
    @Published var isLoading = false
    @Published var error: String?

    func load(id: Int) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            detail = try await APIClient.shared.getTankCheckProposal(id: id)
        } catch {
            self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
