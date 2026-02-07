//
//  Reservation.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import Foundation

struct ReservationRequest: Codable {
    let assetType: String?
    let items: [Int]
    let reservedFor: String?
}
