//
//  EquipmentAsset.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 10.02.26.
//

import Foundation

enum EquipmentAssetType: String, Codable, CaseIterable {
    case equipment
    case tank
    case regulator

    var backendItemType: String {
        switch self {
        case .equipment: return "tl_dc_equipment"
        case .tank: return "tl_dc_tanks"
        case .regulator: return "tl_dc_regulators"
        }
    }
}

struct EquipmentAsset: Identifiable, Equatable, Codable, Hashable {
    let id: Int
    let type: EquipmentAssetType

    let title: String
    let status: String?
    let fee: String?
    let details: String?

    var uniqueKey: String { "\(type.rawValue):\(id)" }
}
