//
//  TankStore.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 09.02.26.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class TankStore: ObservableObject {
    static let shared = TankStore()

    @Published private(set) var myTanks: [ScubaTank] = []

    private let key = "tankstore.myTanks.v1"

    private init() {
        load()
    }

    func add(_ tank: ScubaTank) {
        myTanks.append(tank)
        save()
    }

    func delete(at offsets: IndexSet) {
        myTanks.remove(atOffsets: offsets)
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key) else { return }
        if let decoded = try? JSONDecoder().decode([ScubaTank].self, from: data) {
            myTanks = decoded
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(myTanks) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    func addTank(_ tank: ScubaTank) { add(tank) }
}
