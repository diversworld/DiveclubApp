//
//  OptionsDTOs.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 26.02.26.
//

import Foundation

// /api/regulator/options
struct RegulatorOptionsDTO: Decodable {
    struct RegModels: Decodable {
        let regModel1st: [String: String]
        let regModel2nd: [String: String]
    }
    let manufacturers: [String: String]
    let regulators: [String: RegModels]
}

// /api/sizes/options
struct SizesOptionsDTO: Decodable {
    let sizes: [String: String]
    let manufacturers: [String: String]
}
