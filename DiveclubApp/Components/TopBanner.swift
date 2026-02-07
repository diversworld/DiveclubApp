//
//  TopBanner.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import SwiftUI

struct TopBanner: View {
    
    let title: String
    let message: String
    let color: Color
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
            }
            .padding()
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 6)
            
            Spacer()
        }
        .padding()
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(), value: UUID())
    }
}
