//
//  ProfileView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//


import SwiftUI

struct ProfileView: View {

    @StateObject private var vm = ProfileViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let member = vm.member {
                    ScrollView {
                        VStack(spacing: 16) {

                            headerCard(member: member)

                            infoCard(member: member)

                            actionsCard

                            logoutButton
                        }
                        .padding()
                    }
                } else if let error = vm.errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.orange)
                        Text("Fehler")
                            .font(.title2).bold()
                        Text(error)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    Text("Keine Profildaten vorhanden.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await vm.load()
            }
        }
    }
}

// MARK: - Cards

extension ProfileView {

    private func headerCard(member: Member) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 84, height: 84)
                .foregroundStyle(.blue)

            Text(member.fullName.isEmpty ? member.username : member.fullName)
                .font(.title2)
                .bold()

            Text(member.username)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if member.isInstructor {
                instructorBadge
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func infoCard(member: Member) -> some View {
        VStack(spacing: 12) {
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
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var actionsCard: some View {
        VStack(spacing: 0) {

            // ✅ HIER IST DER NavigationLink, den du vermisst hast
            NavigationLink {
                ChangePasswordView(vm: vm)
            } label: {
                rowLinkLabel(
                    title: "Passwort ändern",
                    systemImage: "key.fill"
                )
            }
            .buttonStyle(.plain)

        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var logoutButton: some View {
        Button(role: .destructive) {
            Task { await AuthManager.shared.logout() }
        } label: {
            Text("Logout")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.red)
        .padding(.top, 4)
    }
}

// MARK: - Components

extension ProfileView {

    private func infoRow(title: String, value: String?) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text((value?.isEmpty == false) ? value! : "–")
                .bold()
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }

    private func rowLinkLabel(title: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.blue)
                .frame(width: 22)

            Text(title)
                .foregroundStyle(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .contentShape(Rectangle())
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
}
