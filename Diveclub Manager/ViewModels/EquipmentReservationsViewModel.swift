//
//  EquipmentReservationsViewModel.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 10.02.26.
//

import Foundation
import Combine

@MainActor
final class EquipmentReservationsViewModel: ObservableObject {
    @Published var reservations: [EquipmentReservation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result: [EquipmentReservation] = try await APIClient.shared.request("reservations")
            reservations = result
        } catch {
            errorMessage = error.localizedDescription
            reservations = []
        }
    }
}
