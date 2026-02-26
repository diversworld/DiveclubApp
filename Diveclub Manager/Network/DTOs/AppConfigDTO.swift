//
//  AppConfigDTO.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 26.02.26.
//

import Foundation

struct AppConfigDTO: Codable {   // ✅ Codable (für Cache)
    let activateApi: Bool?
    let logo: String?
    let infoText: String?
    let newsArchive: Int?

    // ✅ Rechtliches aus Config
    let imprint: String?
    let privacy: String?
    let terms: String?
}
