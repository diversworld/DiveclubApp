//
//  MainTabView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var enrollmentStore = EnrollmentStore.shared
    @StateObject private var auth = AuthManager.shared


    var body: some View {
        TabView {
            // MARK: Events
            NavigationStack {
                EventsView()
                    .navigationTitle("Events")
            }
            .tabItem { Label("Events", systemImage: "calendar") }

            // MARK: Verein (hier gehören TÜV & Flaschen rein)
            NavigationStack {
                List {
                    Section("Verein") {

                        // Schüler: Meine Kurse
                        if auth.isInstructor != true {
                            NavigationLink {
                                MyCoursesView()
                            } label: {
                                Label("Meine Kurse", systemImage: "book")
                            }
                        }

                        NavigationLink {
                            TankChecksView()
                        } label: {
                            Label("TÜV-Prüfungen", systemImage: "checkmark.seal")
                        }

                        NavigationLink {
                            TanksView()
                        } label: {
                            Label("Flaschen", systemImage: "cylinder")
                        }
                    }

                    // Optional: Extra Section nur für Instructor
                    if auth.isInstructor == true {
                        Section("Instruktor") {
                            NavigationLink {
                                InstructorDashboardView()
                            } label: {
                                Label("Instructor Dashboard", systemImage: "person.3")
                            }
                        }
                    }
                }
                .navigationTitle("Verein")
            }
            .tabItem { Label("Verein", systemImage: "building.2") }
            .badge(enrollmentStore.activeCount) // wenn du hier Badge willst

            // MARK: Equipment
            NavigationStack {
                EquipmentView()
                    .navigationTitle("Equipment")
            }
            .tabItem { Label("Equipment", systemImage: "shippingbox") }

            // MARK: Instructor (nur EINMAL, falls du ihn als eigenen Tab willst)
            // statt auth.currentMember?.isInstructor:
            if auth.isInstructor {
                NavigationStack {
                    InstructorDashboardView()
                        .navigationTitle("Instructor")
                }
                .tabItem { Label("Instructor", systemImage: "person.3") }
                .badge(enrollmentStore.activeCount)
            }

            // MARK: Profil
            NavigationStack {
                ProfileView()
                    .navigationTitle("Profil")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Logout") {
                                Task { await auth.logout() }
                            }
                        }
                    }
            }
            .tabItem { Label("Profil", systemImage: "person.circle") }

            // MARK: Settings
            NavigationStack {
                SettingsView()
                    .navigationTitle("Einstellungen")
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
