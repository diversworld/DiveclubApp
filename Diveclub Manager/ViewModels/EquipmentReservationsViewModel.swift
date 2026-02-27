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

    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var reservations: [ReservationDTO] = []

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // je nach deiner APIClient-Normalisierung: "reservations" oder "/reservations"
            let list: [ReservationDTO] = try await APIClient.shared.request("reservations")

            // optional: sortieren nach Datum (neueste zuerst)
            self.reservations = list.sorted { ($0.reservedAt ?? 0) > ($1.reservedAt ?? 0) }

        } catch {
            self.reservations = []
            self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
