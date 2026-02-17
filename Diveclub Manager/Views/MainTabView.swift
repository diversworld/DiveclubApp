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
            NavigationStack {
                HomeView()
            }
            .tabItem { Label("Home", systemImage: "house") }

            if auth.isLoggedIn {
                NavigationStack {
                    EventsView()
                        .navigationTitle("Events")
                }
                .tabItem { Label("Events", systemImage: "calendar") }

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
                .badge(enrollmentStore.badgeCount)

                NavigationStack {
                    TankChecksView()
                        .navigationTitle("TÜV Prüfungen")
                }
                .tabItem { Label("TÜV", systemImage: "checkmark.seal") }

                NavigationStack {
                    EquipmentView()
                        .navigationTitle("Equipment")
                }
                .tabItem { Label("Equipment", systemImage: "shippingbox") }

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

                NavigationStack {
                    SettingsView()
                        .navigationTitle("Einstellungen")
                }
                .tabItem { Label("Settings", systemImage: "gearshape") }
            }
        }
        // ✅ nach dem TabView-Render starten (nicht während body Updates)
        .task {
            if auth.isLoggedIn {
                await enrollmentStore.refresh()
            }
        }
    }
}

#Preview {
    HomeView()
}
