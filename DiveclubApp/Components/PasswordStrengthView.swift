//
//  PasswordStrengthView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

//
//  PasswordStrengthView.swift
//  DiveclubApp
//

import SwiftUI

struct PasswordStrengthView: View {
    let password: String

    private var strength: Double {
        // super simple Heuristik
        var score = 0
        if password.count >= 8 { score += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .lowercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { score += 1 }
        if password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{};':\",.<>?/\\|`~")) != nil { score += 1 }
        return Double(score) / 5.0
    }

    private var label: String {
        switch strength {
        case 0..<0.4: return "Schwach"
        case 0.4..<0.7: return "Mittel"
        default: return "Stark"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Passwort-Stärke")
                Spacer()
                Text(label)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: strength)
        }
    }
}
