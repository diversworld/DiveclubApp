//
//  AuthManager.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

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

    @Published private(set) var currentMember: Member? = nil
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?

    private init() {}

    var isLoggedIn: Bool { currentMember != nil }
    var isInstructor: Bool { currentMember?.isInstructor == true }

    var currentMemberIdInt: Int? {
            guard let id = currentMember?.id else { return nil }
            return Int(id)
        }
    
    /// Beim App-Start: bestehende Session prüfen
    func bootstrap() async {
        isLoading = true
        errorMessage = nil
        //defer { isLoading = false }

        do {
            currentMember = try await APIClient.shared.me()
            // ✅ Badge/Counts laden
            await EnrollmentStore.shared.refresh()
        } catch {
            // Wenn keine Session: kein Fehler-Toast nötig
            //currentMember = nil
            EnrollmentStore.shared.clear()
        }
    }

    func login(username: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            currentMember = try await APIClient.shared.login(username: username, password: password)
            // ✅ Badge/Counts laden
            await EnrollmentStore.shared.refresh()
            return true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            currentMember = nil
            EnrollmentStore.shared.clear()
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

        currentMember = nil
        EnrollmentStore.shared.clear()

        // optional: Cookies löschen, wenn du Session hart resetten willst
        APIClient.shared.clearCookies()
    }

    func refreshMe() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            currentMember = try await APIClient.shared.me()
            await EnrollmentStore.shared.refresh()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
