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
                    do {
                        try await auth.login(username: username, password: password)
                    } catch {
                        errorMessage = "Login fehlgeschlagen"
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            
            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
}

