//
//  LiquidGlassBackground.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 08.02.26.
//

import SwiftUI

struct LiquidGlassBackground: View {
    
    var body: some View {
        ZStack {
            
            // Farbverlauf Hintergrund
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.4),
                    Color.purple.opacity(0.3),
                    Color.teal.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Blur Layer
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        }
    }
}
