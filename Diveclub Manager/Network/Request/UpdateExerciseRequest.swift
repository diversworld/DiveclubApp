//
//  UpdateExerciseRequest.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 08.02.26.
//

import Foundation

struct UpdateExerciseRequest: Encodable {
    let status: String
    let dateCompleted: Int?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case status
        case dateCompleted
        case notes
    }
}
