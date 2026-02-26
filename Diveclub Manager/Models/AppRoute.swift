//
//  AppRoute.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 26.02.26.
//

import Foundation

/// Zentrale Navigation für die ganze App.
/// Hashable ist Pflicht für NavigationPath.
enum AppRoute: Hashable {
    // Equipment / Reservations
    case reservationCreate(preselected: EquipmentAsset?)
    case reservationDetail(id: Int)

    // Settings / Legal
    case settings
    case legalImprint
    case legalPrivacy
    case legalTerms

    // (Optional) weitere Bereiche:
    //case eventDetail(id: Int)
    //case tankCheckDetail(id: Int)
}
