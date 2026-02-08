//
//  ProfileView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

//
//  ProfileView.swift
//  DiveclubApp
//

//
//  ProfileView.swift
//  DiveclubApp
//

import SwiftUI

struct ProfileView: View {
    
    @StateObject private var vm = ProfileViewModel()
    @State private var showSuccessBanner = false
    
    var body: some View {
        NavigationStack {
            
            Group {
                
                // MARK: Loading
                
                if vm.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // MARK: Content
                
                else if let member = vm.member {
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            
                            headerSection(member: member)
                            
                            infoCard(member: member)
                            
                            logoutSection
                        }
                        .padding()
                    }
                }
                
                // MARK: Error
                
                else if let error = vm.errorMessage {
                    Text("Fehler: \(error)")
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await vm.load()
            }
            .overlay(alignment: .top) {
                if showSuccessBanner {
                    successBanner
                }
            }
        }
    }
}

//# MARK: - Sections

extension ProfileView {
    
    // MARK: Header
    
    private func headerSection(member: Member) -> some View {
        VStack(spacing: 8) {
            
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 90)
                .foregroundStyle(.blue)
            
            Text(member.fullName)
                .font(.title2)
                .bold()
            
            Text(member.username)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if member.instructor {
                instructorBadge
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
    
    // MARK: Info Card
    
    private func infoCard(member: Member) -> some View {
        VStack(spacing: 16) {
            
            infoRow(title: "E-Mail", value: member.email)
            infoRow(title: "Straße", value: member.street)
            infoRow(title: "PLZ", value: member.postal)
            infoRow(title: "Ort", value: member.city)
            infoRow(title: "Telefon", value: member.phone)
            infoRow(title: "Mobil", value: member.mobile)
            
            if let birth = member.formattedBirthDate {
                infoRow(title: "Geburtsdatum", value: birth)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
    
    // MARK: Logout
    
    private var logoutSection: some View {
        Button(role: .destructive) {
            Task {
                await AuthManager.shared.logout()
            }
        } label: {
            Text("Logout")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.red)
        .padding(.top)
    }
}

//# MARK: - Components

extension ProfileView {
    
    private func infoRow(title: String, value: String?) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value?.isEmpty == false ? value! : "-")
                .bold()
        }
    }
    
    private var instructorBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill")
            Text("Instructor")
                .bold()
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.blue.opacity(0.15))
        .foregroundStyle(.blue)
        .clipShape(Capsule())
    }
    
    private var successBanner: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
            Text("Profil aktualisiert")
        }
        .padding()
        .background(.green)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding()
        .transition(.move(edge: .top))
    }
}
