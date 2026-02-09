//
//  AuthManager.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published private(set) var me: MeDTO?
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?

    private init() {}

    var isLoggedIn: Bool { me != nil }
    var isInstructor: Bool { me?.isInstructor == true }
    var currentMember: MeDTO? { me }

    func bootstrap() async {
        // Beim App-Start: bestehende Session prüfen
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            me = try await APIClient.shared.me()
        } catch {
            // Wenn keine Session: me bleibt nil (kein Fehler-Toast nötig)
            me = nil
        }
    }

    func login(username: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            me = try await APIClient.shared.login(username: username, password: password)
            return true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            me = nil
            return false
        }
    }

    func logout() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await APIClient.shared.logout()
        } catch {
            // Auch wenn Logout API failt, local state leeren
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        me = nil
    }

    func refreshMe() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            me = try await APIClient.shared.me()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
