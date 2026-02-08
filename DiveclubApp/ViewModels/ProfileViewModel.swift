//
//  ProfileViewModel.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    
    @Published var member: Member?
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var saveSuccess = false
    
    // MARK: Load
    
    func load() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result: Member =
                try await APIClient.shared.request("me")
            
            member = result
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: Save
    
    func save(firstname: String,
              lastname: String,
              email: String,
              street: String,
              postal: String,
              city: String,
              phone: String,
              mobile: String,
              dateOfBirth: Date?) async {
        
        guard !isSaving else { return }
        
        isSaving = true
        errorMessage = nil
        saveSuccess = false
        
        defer { isSaving = false }
        
        do {
            var payload: [String: Any] = [
                "firstname": firstname,
                "lastname": lastname,
                "email": email,
                "street": street,
                "postal": postal,
                "city": city,
                "phone": phone,
                "mobile": mobile
            ]
            
            if let date = dateOfBirth {
                payload["dateOfBirth"] = Int(date.timeIntervalSince1970)
            }
            
            let body = try JSONSerialization.data(withJSONObject: payload)
            
            try await APIClient.shared.requestWithoutResponse(
                "me",
                method: "PATCH",
                body: body
            )
            
            await load()
            saveSuccess = true
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Passwort ändern

    func changePassword(current: String, new: String) async {
        
        guard !isSaving else { return }
        
        isSaving = true
        errorMessage = nil
        saveSuccess = false
        
        defer { isSaving = false }
        
        do {
            let payload = [
                "currentPassword": current,
                "newPassword": new
            ]
            
            let body = try JSONSerialization.data(withJSONObject: payload)
            
            try await APIClient.shared.requestWithoutResponse(
                "me/password",
                method: "PATCH",
                body: body
            )
            
            saveSuccess = true
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
