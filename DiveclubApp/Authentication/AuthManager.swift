//
//  AuthManager.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import Foundation
import Combine

@MainActor
class AuthManager: ObservableObject {
    
    static let shared = AuthManager()

    @Published var memberId: Int?
    @Published var isAuthenticated = false
    @Published var isCheckingSession = true
    
    private init() {}
    
    func login(username: String, password: String) async throws {
        
        let requestModel = LoginRequest(
            username: username,
            password: password
        )
        
        let body = try JSONEncoder().encode(requestModel)
        
        let response: LoginResponse = try await APIClient.shared.request(
            "login",
            method: "POST",
            body: body
        )
        
        guard response.success else {
            throw URLError(.userAuthenticationRequired)
        }
        
        UserDefaults.standard.set(response.member.id, forKey: "memberId")
        
        memberId = response.member.id
        isAuthenticated = true
    }
    
    func logout() async {
        do {
            try await APIClient.shared.requestWithoutResponse(
                "logout",
                method: "POST",
                body: nil
            )
        } catch {
            print("Logout request failed:", error)
        }
        
        UserDefaults.standard.removeObject(forKey: "memberId")
        
        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
        
        memberId = nil
        isAuthenticated = false
    }
    
    func checkSession() async {
        isCheckingSession = true
        
        do {
            _ = try await APIClient.shared.request("me") as Member
            isAuthenticated = true
        } catch {
            isAuthenticated = false
        }
        
        isCheckingSession = false
    }
}
