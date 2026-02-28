//
//  SplashView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 28.02.26.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            // Hintergrund
            LinearGradient(
                colors: [Color.blue.opacity(0.85), Color.cyan.opacity(0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(.white)

                Text("Diveclub App")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2)
                    .padding(.top, 8)
            }
        }
    }
}
