//
//  Reservation.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import Foundation

struct Reservation: Codable, Identifiable {
    let id: Int
    let eventId: Int
}
