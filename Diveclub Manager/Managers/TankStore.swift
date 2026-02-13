//
//  TankStore.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 09.02.26.
//

import Foundation
import Combine

struct SavedTank: Codable, Identifiable, Equatable {
    let id: UUID
    var serialNumber: String
    var manufacturer: String
    var bazNumber: String
    var size: String
    var o2clean: Bool

    init(
        id: UUID = UUID(),
        serialNumber: String,
        manufacturer: String = "",
        bazNumber: String = "",
        size: String,
        o2clean: Bool = false
    ) {
        self.id = id
        self.serialNumber = serialNumber
        self.manufacturer = manufacturer
        self.bazNumber = bazNumber
        self.size = size
        self.o2clean = o2clean
    }
}

@MainActor
final class TankStore: ObservableObject {
    static let shared = TankStore()

    @Published private(set) var tanks: [SavedTank] = []

    private let key = "savedTanks.v1"

    private init() {
        loadFromDefaults()
    }

    func addOrUpdate(_ tank: SavedTank) {
        if let idx = tanks.firstIndex(where: { $0.id == tank.id }) {
            tanks[idx] = tank
        } else {
            tanks.append(tank)
        }
        persist()
    }

    func delete(_ tank: SavedTank) {
        tanks.removeAll { $0.id == tank.id }
        persist()
    }

    func persist() {
        do {
            let data = try JSONEncoder().encode(tanks)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            #if DEBUG
            print("❌ TankStore persist failed:", error)
            #endif
        }
    }

    func loadFromDefaults() {
        guard let data = UserDefaults.standard.data(forKey: key) else { return }
        do {
            tanks = try JSONDecoder().decode([SavedTank].self, from: data)
        } catch {
            #if DEBUG
            print("❌ TankStore decode failed:", error)
            #endif
        }
    }
}
