//
//  NavigationStore.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 26.02.26.
//
import SwiftUI
import Combine

@MainActor
final class NavigationStore: ObservableObject {

    enum Tab: Hashable {
        case home, events, courses, tankChecks, equipment, profile, settings
    }

    @Published var selectedTab: Tab = .home

    // eigener Backstack je Tab
    @Published var homePath = NavigationPath()
    @Published var eventsPath = NavigationPath()
    @Published var coursesPath = NavigationPath()
    @Published var tankChecksPath = NavigationPath()
    @Published var equipmentPath = NavigationPath()
    @Published var profilePath = NavigationPath()
    @Published var settingsPath = NavigationPath()

    func pathBinding(for tab: Tab) -> Binding<NavigationPath> {
        switch tab {
        case .home: return Binding(get: { self.homePath }, set: { self.homePath = $0 })
        case .events: return Binding(get: { self.eventsPath }, set: { self.eventsPath = $0 })
        case .courses: return Binding(get: { self.coursesPath }, set: { self.coursesPath = $0 })
        case .tankChecks: return Binding(get: { self.tankChecksPath }, set: { self.tankChecksPath = $0 })
        case .equipment: return Binding(get: { self.equipmentPath }, set: { self.equipmentPath = $0 })
        case .profile: return Binding(get: { self.profilePath }, set: { self.profilePath = $0 })
        case .settings: return Binding(get: { self.settingsPath }, set: { self.settingsPath = $0 })
        }
    }

    func push(_ route: AppRoute, in tab: Tab? = nil) {
        let t = tab ?? selectedTab
        switch t {
        case .home: homePath.append(route)
        case .events: eventsPath.append(route)
        case .courses: coursesPath.append(route)
        case .tankChecks: tankChecksPath.append(route)
        case .equipment: equipmentPath.append(route)
        case .profile: profilePath.append(route)
        case .settings: settingsPath.append(route)
        }
    }

    func popToRoot(of tab: Tab? = nil) {
        let t = tab ?? selectedTab
        switch t {
        case .home: homePath = NavigationPath()
        case .events: eventsPath = NavigationPath()
        case .courses: coursesPath = NavigationPath()
        case .tankChecks: tankChecksPath = NavigationPath()
        case .equipment: equipmentPath = NavigationPath()
        case .profile: profilePath = NavigationPath()
        case .settings: settingsPath = NavigationPath()
        }
    }
}
