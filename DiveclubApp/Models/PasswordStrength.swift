//
//  PasswordStrength.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import Foundation

enum PasswordStrength: Int {
    case veryWeak = 0
    case weak = 1
    case medium = 2
    case strong = 3
    case veryStrong = 4
    
    var color: String {
        switch self {
        case .veryWeak: return "red"
        case .weak: return "orange"
        case .medium: return "yellow"
        case .strong: return "mint"
        case .veryStrong: return "green"
        }
    }
    
    var description: String {
        switch self {
        case .veryWeak: return "Sehr schwach"
        case .weak: return "Schwach"
        case .medium: return "Mittel"
        case .strong: return "Stark"
        case .veryStrong: return "Sehr stark"
        }
    }
}

struct PasswordValidator {
    
    static func evaluate(_ password: String) -> PasswordStrength {
        
        var score = 0
        
        if password.count >= 8 { score += 1 }
        if password.range(of: "[A-Z]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[a-z]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[0-9]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil { score += 1 }
        
        return PasswordStrength(rawValue: min(score, 4)) ?? .veryWeak
    }
}

