//
//  StartView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 10.02.26.
//

import SwiftUI

struct StartView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {

                Image("Diversworld") // Name aus Assets.xcassets
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .shadow(radius: 6)

                Text("Diveclub Manager")
                    .font(.title.bold())

                NavigationLink("Anmelden") {
                    LoginView()
                }
                .buttonStyle(.borderedProminent)

                NavigationLink("Einstellungen") {
                    SettingsView()
                }
                .buttonStyle(.bordered)

                Spacer()
            }
            .padding()
        }
    }
}
