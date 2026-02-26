//
//  EquipmentView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import SwiftUI

struct EquipmentView: View {

    var body: some View {
        List {
            Section {
                NavigationLink {
                    EquipmentCatalogView()
                } label: {
                    Label("Katalog+#", systemImage: "shippingbox")
                }

                NavigationLink {
                    EquipmentReservationCreateView()
                } label: {
                    Label("Neue Reservierung+#", systemImage: "plus.circle")
                }

                NavigationLink {
                    EquipmentReservationsView()
                } label: {
                    Label("Meine Reservierungen+#", systemImage: "list.bullet.rectangle")
                }
            }

            Section("Hinweis+#") {
                Text("Abholung/Rückgabe erfolgt durch Admin im Backend. In der App kannst du reservieren und den Status verfolgen.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Equipment")
    }
}
