//
//  Tank.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import Foundation

struct Tank: Codable, Identifiable {
    let id: Int
    let serialNumber: String?
    let size: String?
    let lastInspection: Int?        // Unix Timestamp (Sekunden) oder nil
    let nextInspection: Int?        // optional, falls Backend liefert
    let ownerMemberId: Int?         // optional, falls Backend liefert (für "meine Flaschen")

    enum CodingKeys: String, CodingKey {
        case id
        case serialNumber = "serial_number"
        case size
        case lastInspection = "last_inspection"
        case nextInspection = "next_inspection"
        case ownerMemberId = "owner_member_id"
    }

    var displayTitle: String {
        let sn = (serialNumber?.isEmpty == false) ? serialNumber! : "ohne Seriennr."
        let s = (size?.isEmpty == false) ? " • \(size!)" : ""
        return "\(sn)\(s)"
    }

    var isDueSoonOrOverdue: Bool {
        guard let nextInspection else { return false }
        return nextInspection <= Int(Date().timeIntervalSince1970)
    }
}
