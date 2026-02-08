//
//  AuthManager.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import Foundation
import Combine

@MainActor
final class AuthManager: ObservableObject {
    
    static let shared = AuthManager()
    
    @Published var isAuthenticated = false
    @Published var currentMember: Member?
    @Published var isCheckingSession = false
    
    private init() {}
    
    // MARK: - Login
    
    func login(username: String, password: String) async {
        do {
            let response: LoginResponse =
                try await APIClient.shared.request(
                    "login",
                    method: "POST",
                    body: try JSONEncoder().encode(
                        LoginRequest(username: username, password: password)
                    )
                )
            
            currentMember = response.member
            isAuthenticated = true
            
            await EnrollmentStore.shared.load()
            
        } catch {
            isAuthenticated = false
            currentMember = nil
        }
    }
    
    // MARK: - Logout
    
    func logout() async {
        do {
            try await APIClient.shared.requestWithoutResponse(
                "logout",
                method: "POST",
                body: nil
            )
        } catch {}
        
        currentMember = nil
        isAuthenticated = false
    }
    
    // MARK: - Session Check
    
    func checkSession() async {
        isCheckingSession = true
        
        do {
            let member: Member =
                try await APIClient.shared.request("me")
            
            currentMember = member
            isAuthenticated = true
            
            await EnrollmentStore.shared.load()
            
        } catch {
            isAuthenticated = false
            currentMember = nil
        }
        
        isCheckingSession = false
    }
}
