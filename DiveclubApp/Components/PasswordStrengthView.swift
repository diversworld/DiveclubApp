//
//  PasswordStrengthView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import SwiftUI

struct PasswordStrengthView: View {
    
    let password: String
    
    var strength: PasswordStrength {
        PasswordValidator.evaluate(password)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(strength.color))
                        .frame(
                            width: geo.size.width * CGFloat(strength.rawValue + 1) / 5,
                            height: 6
                        )
                        .animation(.easeInOut, value: strength.rawValue)
                }
            }
            .frame(height: 6)
            
            Text(strength.description)
                .font(.caption)
                .foregroundColor(Color(strength.color))
        }
    }
}
