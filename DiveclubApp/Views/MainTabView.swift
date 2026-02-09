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
            .tabItem {
                Label("Events", systemImage: "calendar")
            }
            
            // 👉 Schüler: Meine Kurse
            if auth.currentMember?.isInstructor != true {
                NavigationStack {
                    MyCoursesView()
                }
                .tabItem {
                    Label("Meine Kurse", systemImage: "book")
                }
                .badge(enrollmentStore.activeCount)
            }

            // 👉 Instructor: Instructor Dashboard
            if auth.currentMember?.isInstructor == true {
                NavigationStack {
                    InstructorDashboardView()
                }
                .tabItem {
                    Label("Instructor", systemImage: "person.3")
                }
                .badge(enrollmentStore.activeCount)
            }
            
            
            // MARK: Reservierungen
            NavigationStack {
                ReservationsView()
                    .navigationTitle("Reservierungen")
            }
            .tabItem {
                Label("Reservierungen", systemImage: "list.bullet")
            }
            
            // MARK: Equipment
            NavigationStack {
                EquipmentView()
                    .navigationTitle("Equipment")
            }
            .tabItem {
                Label("Equipment", systemImage: "shippingbox")
            }
            
            // MARK: Instructor
            if AuthManager.shared.currentMember?.isInstructor == true {
                NavigationStack {
                    InstructorDashboardView()
                        .navigationTitle("Instructor")
                }
                .tabItem {
                    Label("Instructor", systemImage: "person.3")
                }
            }
            
            // MARK: Profil
            NavigationStack {
                ProfileView()
                    .navigationTitle("Profil")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Logout") {
                                Task {
                                    await AuthManager.shared.logout()
                                }
                            }
                        }
                    }
            }
            .tabItem {
                Label("Profil", systemImage: "person.circle")
            }
            
            // MARK: Settings
            NavigationStack {
                SettingsView()
                    .navigationTitle("Einstellungen")
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
    }
}
