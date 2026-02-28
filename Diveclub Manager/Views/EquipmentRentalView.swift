//
//  EquipmentRentalView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 10.02.26.
//
import SwiftUI

struct EquipmentRentalView: View {
    @EnvironmentObject private var nav: NavigationStore
    @StateObject private var vm = EquipmentRentalViewModel()

    var body: some View {
        VStack(spacing: 12) {

            Picker("Kategorie", selection: $vm.selectedCategory) {
                ForEach(EquipmentRentalViewModel.Category.allCases) { cat in
                    Text(cat.rawValue.capitalized).tag(cat)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: vm.selectedCategory) { _, _ in
                Task { await vm.loadAssets() }
            }

            List(vm.visibleAssets, id: \.uniqueKey) { asset in
                let isSel = vm.isSelected(asset)

                Button {
                    // ✅ Feedback: Auswahl togglen
                    if !isSel { vm.toggleSelection(asset) }

                    // ✅ Navigation per Route (mit Kontext)
                    nav.push(.reservationCreate(preselected: asset), in: .equipment)
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: isSel ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(isSel ? .green : .secondary)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(asset.title)

                            if let details = asset.details, !details.isEmpty {
                                Text(details)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(3)
                            } else if let status = asset.status {
                                Text(status)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.body)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 6)
                    .background(isSel ? Color.green.opacity(0.08) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("Reservierungen")
        .task { await vm.loadAssets() }
    }
}
