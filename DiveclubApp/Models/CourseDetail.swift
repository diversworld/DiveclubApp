//
//  CourseDetail.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 08.02.26.
//

import Foundation

struct CourseDetail: Decodable, Identifiable {
    let id: Int
    let title: String
    let description: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
    }
}
