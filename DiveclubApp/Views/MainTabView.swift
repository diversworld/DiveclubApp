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

            // MARK: Kurse / Instructor
            NavigationStack {
                if auth.isInstructor {
                    InstructorDashboardView()
                        .navigationTitle("Instructor")
                } else {
                    MyCoursesView()
                        .navigationTitle("Meine Kurse")
                }
            }
            .tabItem {
                if auth.isInstructor {
                    Label("Instructor", systemImage: "person.3")
                } else {
                    Label("Meine Kurse", systemImage: "book")
                }
            }
            .badge(enrollmentStore.activeCount) //enrollmentStore.badgeCount

            // MARK: TÜV Prüfungen
            NavigationStack {
                TankChecksView()
                    .navigationTitle("TÜV Prüfungen")
            }
            .tabItem { Label("TÜV", systemImage: "checkmark.seal") }

            // MARK: Equipment
            NavigationStack {
                EquipmentView()
                    .navigationTitle("Equipment")
            }
            .tabItem { Label("Equipment", systemImage: "shippingbox") }

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
        .task {
            await enrollmentStore.refresh()
        }
    }
}
