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

    @StateObject private var nav = NavigationStore()

    var body: some View {
        TabView(selection: $nav.selectedTab) {

            NavigationStack(path: nav.pathBinding(for: .home)) {
                HomeView()
                    .navigationDestination(for: AppRoute.self) { route in
                        routeDestination(route)
                    }
            }
            .tabItem { Label("Home", systemImage: "house") }
            .tag(NavigationStore.Tab.home)

            if auth.isLoggedIn {

                NavigationStack(path: nav.pathBinding(for: .events)) {
                    EventsView()
                        .navigationTitle("Events")
                        .navigationDestination(for: AppRoute.self) { route in
                            routeDestination(route)
                        }
                }
                .tabItem { Label("Events", systemImage: "calendar") }
                .tag(NavigationStore.Tab.events)

                NavigationStack(path: nav.pathBinding(for: .courses)) {
                    Group {
                        if auth.isInstructor {
                            InstructorDashboardView()
                                .navigationTitle("Instructor")
                        } else {
                            MyCoursesView()
                                .navigationTitle("Meine Kurse")
                        }
                    }
                    .navigationDestination(for: AppRoute.self) { route in
                        routeDestination(route)
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
                .tag(NavigationStore.Tab.courses)

                NavigationStack(path: nav.pathBinding(for: .tankChecks)) {
                    TankChecksView()
                        .navigationTitle("TÜV Prüfungen")
                        .navigationDestination(for: AppRoute.self) { route in
                            routeDestination(route)
                        }
                }
                .tabItem { Label("TÜV", systemImage: "checkmark.seal") }
                .tag(NavigationStore.Tab.tankChecks)

                NavigationStack(path: nav.pathBinding(for: .equipment)) {
                    EquipmentReservationsView()
                        .navigationTitle("Equipment Verleih")
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button {
                                    nav.push(.reservationCreate(preselected: nil), in: .equipment)
                                } label: {
                                    Image(systemName: "plus")
                                }
                            }
                        }
                        .navigationDestination(for: AppRoute.self) { route in
                            routeDestination(route)
                        }
                }
                .tabItem { Label("Equipment", systemImage: "tray.full") }
                .tag(NavigationStore.Tab.equipment)

                NavigationStack(path: nav.pathBinding(for: .profile)) {
                    ProfileView()
                        .navigationTitle("Profil")
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Logout") {
                                    Task { await auth.logout() }
                                }
                            }
                        }
                        .navigationDestination(for: AppRoute.self) { route in
                            routeDestination(route)
                        }
                }
                .tabItem { Label("Profil", systemImage: "person.circle") }
                .tag(NavigationStore.Tab.profile)

                NavigationStack(path: nav.pathBinding(for: .settings)) {
                    SettingsView()
                        .navigationTitle("Einstellungen")
                        .navigationDestination(for: AppRoute.self) { route in
                            routeDestination(route)
                        }
                }
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(NavigationStore.Tab.settings)
            }
        }
        .environmentObject(nav) // ✅ Navigation global verfügbar
        .task {
            if auth.isLoggedIn {
                await enrollmentStore.refresh()
            }
        }
    }

    // MARK: - Route resolver (1 Stelle für die ganze App)

    @ViewBuilder
    private func routeDestination(_ route: AppRoute) -> some View {
        switch route {

        case .reservationCreate(let preselected):
            ReservationView(preselected: preselected)
                .navigationTitle("Neue Reservierung")

        case .reservationDetail(let id):
            EquipmentReservationDetailView(reservationId: id)

        case .settings:
            SettingsView().navigationTitle("Einstellungen")

        case .legalImprint:
            LegalHTMLView(title: "Impressum", html: AppSettingsManager.shared.imprintHTML)

        case .legalPrivacy:
            LegalHTMLView(title: "Datenschutz", html: AppSettingsManager.shared.privacyHTML)

        case .legalTerms:
            LegalHTMLView(title: "Nutzungsbedingungen", html: AppSettingsManager.shared.termsHTML)
        }
    }
}
