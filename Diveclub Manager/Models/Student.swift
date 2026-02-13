//
//  Student.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import Foundation

struct Student: Codable, Identifiable {
    
    let id: Int
    let firstname: String?
    let lastname: String?
    let email: String?
    let progress: Double?
    
    var fullName: String {
        "\(firstname ?? "") \(lastname ?? "")"
    }
    
    var progressValue: Double {
        progress ?? 0.0
    }
}
