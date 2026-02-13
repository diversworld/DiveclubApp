//
//  EditProfileView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 08.02.26.
//

import SwiftUI

struct EditProfileView: View {
    
    @ObservedObject var vm: ProfileViewModel
    
    @State private var firstname = ""
    @State private var lastname = ""
    @State private var email = ""
    @State private var street = ""
    @State private var postal = ""
    @State private var city = ""
    @State private var phone = ""
    @State private var mobile = ""
    @State private var birthDate: Date?
    
    var body: some View {
        Form {
            Section("Persönlich") {
                TextField("Vorname", text: $firstname)
                TextField("Nachname", text: $lastname)
                TextField("E-Mail", text: $email)
                    .keyboardType(.emailAddress)
            }
            
            Section("Adresse") {
                TextField("Straße", text: $street)
                TextField("PLZ", text: $postal)
                TextField("Ort", text: $city)
            }
            
            Section("Kontakt") {
                TextField("Telefon", text: $phone)
                TextField("Mobil", text: $mobile)
            }
            
            Section("Geburtsdatum") {
                DatePicker(
                    "Geburtsdatum",
                    selection: Binding(
                        get: { birthDate ?? Date() },
                        set: { birthDate = $0 }
                    ),
                    displayedComponents: .date
                )
            }
            
            Button {
                Task {
                    await vm.save(
                        firstname: firstname,
                        lastname: lastname,
                        email: email,
                        street: street,
                        postal: postal,
                        city: city,
                        phone: phone,
                        mobile: mobile,
                        dateOfBirth: birthDate
                    )
                }
            } label: {
                if vm.isSaving {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Speichern")
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Profil bearbeiten")
        .onAppear {
            guard let m = vm.member else { return }
            firstname = m.firstname ?? ""
            lastname = m.lastname ?? ""
            email = m.email ?? ""
            street = m.street ?? ""
            postal = m.postal ?? ""
            city = m.city ?? ""
            phone = m.phone ?? ""
            mobile = m.mobile ?? ""
            birthDate = m.birthDate
        }
        .overlay(alignment: .top) {
            if vm.saveSuccess {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Gespeichert")
                }
                .padding()
                .background(.green)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()
                .transition(.move(edge: .top))
            }
        }
    }
}
