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

    /// Backend erwartet: item_type (string). Du kannst hier die Werte festlegen.
    /// WICHTIG: Diese Strings müssen zu deinem Backend passen!
    var backendItemType: String {
        switch self {
        case .equipment: return "equipment"
        case .tank: return "tank"
        case .regulator: return "regulator"
        }
    }
}

struct EquipmentAsset: Identifiable, Equatable {
    let id: Int
    let type: EquipmentAssetType

    let title: String
    let status: String?
    let fee: String?
    let details: String?
}
