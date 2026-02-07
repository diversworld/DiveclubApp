//
//  ProfileView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import SwiftUI

struct ProfileView: View {
    
    @StateObject private var vm = ProfileViewModel()
    
    @State private var firstname = ""
    @State private var lastname = ""
    @State private var email = ""
    @State private var street = ""
    @State private var postal = ""
    @State private var city = ""
    @State private var phone = ""
    @State private var mobile = ""
    @State private var birthDate = Date()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Group {
                    if vm.isLoading {
                        ProgressView()
                    }
                    else if vm.member != nil {
                        
                        Form {
                            
                            Section("Persönlich") {
                                TextField("Vorname", text: $firstname)
                                TextField("Nachname", text: $lastname)
                                TextField("E-Mail", text: $email)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                
                                DatePicker(
                                    "Geburtsdatum",
                                    selection: $birthDate,
                                    displayedComponents: .date
                                )
                            }
                            
                            Section("Adresse") {
                                TextField("Straße", text: $street)
                                TextField("PLZ", text: $postal)
                                    .keyboardType(.numberPad)
                                TextField("Ort", text: $city)
                            }
                            
                            Section("Kontakt") {
                                TextField("Telefon", text: $phone)
                                    .keyboardType(.phonePad)
                                TextField("Mobil", text: $mobile)
                                    .keyboardType(.phonePad)
                            }
                            
                            Section {
                                Button("Speichern") {
                                    Task {
                                        await save()
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            
                            Section {
                                Button("Logout", role: .destructive) {
                                    Task {
                                        await AuthManager.shared.logout()
                                    }
                                }
                            }
                        }
                    }
                    else if let error = vm.errorMessage {
                        Text("Fehler: \(error)")
                    }
                }
            }
            .navigationTitle("Profil bearbeiten")
            .task {
                await vm.load()
                fillForm()
            }
            .alert("Erfolg",
                   isPresented: $vm.showSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Profil wurde erfolgreich gespeichert.")
            }
            .onChange(of: vm.showBanner) { _, newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            vm.showBanner = false
                        }
                    }
                }
            }
            NavigationLink("Passwort ändern") {
                ChangePasswordView()
            }
        }
    }
    
    private func fillForm() {
        guard let member = vm.member else { return }
        
        firstname = member.firstname ?? ""
        lastname  = member.lastname ?? ""
        email     = member.email ?? ""
        street    = member.street ?? ""
        postal    = member.postal ?? ""
        city      = member.city ?? ""
        phone     = member.phone ?? ""
        mobile    = member.mobile ?? ""
        
        if let birth = member.birthDate {
            birthDate = birth
        }
    }
    
    private func save() async {
        await vm.updateProfile(
            firstname: firstname,
            lastname: lastname,
            email: email,
            street: street,
            postal: postal,
            city: city,
            phone: phone,
            mobile: mobile,
            dateOfBirth: birthDate.timeIntervalSince1970
        )
    }
}
