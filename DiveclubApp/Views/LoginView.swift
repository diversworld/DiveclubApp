//
//  LoginView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import SwiftUI

struct LoginView: View {
    
    @State private var username = ""
    @State private var password = ""
    @State private var errorMessage: String?
    
    @StateObject private var auth = AuthManager.shared
    
    var body: some View {
        VStack(spacing: 12) {
            Image("Diversworld")
                .resizable()
                .scaledToFit()
                .frame(width: 90, height: 90)

            Text("Diveclub")
                .font(.title.bold())
        }
        .padding(.bottom, 20)
        VStack(spacing: 20) {
            
            Text("Diveclub Login")
                .font(.largeTitle)
            
            TextField("Benutzername", text: $username)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
            
            SecureField("Passwort", text: $password)
                .textFieldStyle(.roundedBorder)
            
            Button("Login") {
                Task {
                    await AuthManager.shared.login(
                        username: username,
                        password: password
                    )
                }
            }
            .buttonStyle(.borderedProminent)
            .navigationTitle("Login")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                            .navigationTitle("Einstellungen")
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            
            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
}

