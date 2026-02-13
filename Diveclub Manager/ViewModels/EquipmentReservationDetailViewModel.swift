//
//  EquipmentReservationDetailViewModel.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 10.02.26.
//

import Foundation
import Combine

@MainActor
final class EquipmentReservationDetailViewModel: ObservableObject {

    @Published var detail: EquipmentReservationDetail?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let reservationId: Int

    init(reservationId: Int) {
        self.reservationId = reservationId
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result: EquipmentReservationDetail = try await APIClient.shared.request("reservations/\(reservationId)")
            detail = result
        } catch {
            errorMessage = error.localizedDescription
            detail = nil
        }
    }
}
