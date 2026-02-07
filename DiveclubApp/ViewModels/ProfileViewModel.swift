//
//  ProfileViewModel.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import Foundation
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    
    @Published var member: Member?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showSuccess = false
    @Published var showBanner = false
    @Published var bannerMessage = ""
    
    func load() async {
        isLoading = true
        errorMessage = nil
        
        do {
            member = try await APIClient.shared.request("me")
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func updateProfile(
        firstname: String,
        lastname: String,
        email: String,
        street: String,
        postal: String,
        city: String,
        phone: String,
        mobile: String,
        dateOfBirth: TimeInterval
    ) async {
        
        isLoading = true
        errorMessage = nil
        showBanner = true
        bannerMessage = "Profil erfolgreich gespeichert"
        
        let request = UpdateProfileRequest(
            firstname: firstname,
            lastname: lastname,
            email: email,
            street: street,
            postal: postal,
            city: city,
            phone: phone,
            mobile: mobile,
            dateOfBirth: dateOfBirth
        )
        
        do {
            let body = try JSONEncoder().encode(request)
            
            try await APIClient.shared.requestWithoutResponse(
                "me",
                method: "PATCH",
                body: body
            )
            
            showSuccess = true   // 👈 Erfolg setzen
            
            await load()         // neu laden
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func changePassword(current: String, new: String) async {
        
        let request = ChangePasswordRequest(
            currentPassword: current,
            newPassword: new
        )
        
        do {
            let body = try JSONEncoder().encode(request)
            
            try await APIClient.shared.requestWithoutResponse(
                "me/password",
                method: "PATCH",
                body: body
            )
            
            bannerMessage = "Passwort erfolgreich geändert"
            showBanner = true
            
        } catch {
            errorMessage = "Passwortänderung fehlgeschlagen"
        }
    }
}
