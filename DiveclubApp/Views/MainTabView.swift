//
//  MainTabView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import SwiftUI

struct MainTabView: View {
    
    var body: some View {
        NavigationStack {
            TabView {
                
                EventsView()
                    .tabItem {
                        Label("Events", systemImage: "calendar")
                    }
                
                ReservationsView()
                    .tabItem {
                        Label("Reservierungen", systemImage: "list.bullet")
                    }
                
                EquipmentView()
                    .tabItem {
                        Label("Equipment", systemImage: "shippingbox")
                    }
                ProfileView()
                    .tabItem {
                        Label("Profil", systemImage: "person.circle")
                    }
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
            }
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
    }
}
