//
//  EquipmentCatalogViewModel.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 10.02.26.
//

import Foundation
import Combine

@MainActor
final class EquipmentCatalogViewModel: ObservableObject {

    @Published var equipment: [EquipmentAsset] = []
    @Published var tanks: [EquipmentAsset] = []
    @Published var regulators: [EquipmentAsset] = []

    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let eq: [EquipmentDTO] = APIClient.shared.request("equipment")
            async let tk: [TankDTO] = APIClient.shared.request("tanks")
            async let rg: [RegulatorDTO] = APIClient.shared.request("regulators")

            let (eqRes, tkRes, rgRes) = try await (eq, tk, rg)

            equipment = eqRes.map { $0.toAsset() }
            tanks = tkRes.map { $0.toAsset() }
            regulators = rgRes.map { $0.toAsset() }

        } catch {
            errorMessage = error.localizedDescription
            equipment = []
            tanks = []
            regulators = []
        }
    }
}
