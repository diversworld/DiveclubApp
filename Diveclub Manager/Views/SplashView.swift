//
//  SplashView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 28.02.26.
//

import SwiftUI

struct SplashView: View {
    @State private var blurAmount: CGFloat = 0
    @State private var dimAmount: CGFloat = 0.0

    @State private var showLogo = false
    @State private var logoFloatUp = false
    @State private var glowPulse = false

    var body: some View {
        ZStack {
            // Background: identisch zum LaunchScreen → Crossfade-Effekt
            Image("LaunchBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .blur(radius: blurAmount) // ✅ nur im Splash, nicht im LaunchScreen
                .overlay(Color.black.opacity(dimAmount)) // ✅ dimmt das "zu helle" Bild

            // Logo (über dem Taucher)
            Image("LaunchLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 120)     // ✅ kleiner
                .offset(y: -250)       // ✅ über dem Taucher
                .opacity(showLogo ? 1 : 0)
                .scaleEffect(showLogo ? 1.0 : 0.86)
                .shadow(color: .white.opacity(glowPulse ? 0.35 : 0.18),
                        radius: glowPulse ? 18 : 10,
                        x: 0, y: 0)     // ✅ leichter Glow
                .offset(y: logoFloatUp ? -6 : 6) // ✅ “float”
                .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true),
                           value: logoFloatUp)
        }
        .onAppear {
            // 0) Start: exakt wie LaunchScreen (kein blur, leichtes dim)
            blurAmount = 0
            dimAmount = 0.30

            // 1) Cinematic: Hintergrund langsam weicher + etwas dunkler
            withAnimation(.easeInOut(duration: 1.4)) {
                blurAmount = 1.6
                dimAmount = 0.38
            }

            // 2) Logo delayed rein
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.spring(response: 0.65, dampingFraction: 0.78)) {
                    showLogo = true
                }
            }

            // 3) Float & Glow starten
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                logoFloatUp = true
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    glowPulse = true
                }
            }
        }
    }
}
