//
//  EquipmentReservationDetailView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 10.02.26.
//

import SwiftUI

struct EquipmentReservationDetailView: View {

    @StateObject private var vm: EquipmentReservationDetailViewModel

    @State private var equipmentOptions: EquipmentOptionsDTO?

    private func typeLabel(for key: String?) -> String? {
        guard let key, let opts = equipmentOptions?.types[key] else { return nil }
        return opts.name
    }
    private func subTypeLabel(for tKey: String?, sKey: String?) -> String? {
        guard let tKey, let sKey, let type = equipmentOptions?.types[tKey] else { return nil }
        return type.subtypes[sKey]
    }

    init(reservationId: Int) {
        _vm = StateObject(wrappedValue: EquipmentReservationDetailViewModel(reservationId: reservationId))
    }

    private func statusLabel(_ raw: String?) -> (text: String, color: Color) {
        let key = (raw ?? "").lowercased()
        switch key {
        case "pending", "open":
            return ("Offen", .orange)
        case "reserved":
            return ("Reserviert", .orange)
        case "confirmed", "approved":
            return ("Bestätigt", .blue)
        case "picked_up", "active":
            return ("Ausgegeben", .purple)
        case "returned", "closed":
            return ("Zurückgegeben", .green)
        case "cancelled", "canceled":
            return ("Storniert", .red)
        default:
            return ((raw ?? "Unbekannt").capitalized, .secondary)
        }
    }

    private func formatDateTime(_ unix: Int) -> String {
        let d = Date(timeIntervalSince1970: TimeInterval(unix))
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: d)
    }

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let err = vm.errorMessage {
                ContentUnavailableView("Fehler", systemImage: "exclamationmark.triangle", description: Text(err))
            } else if let d = vm.detail {
                detailView(d)
            } else {
                ContentUnavailableView("Keine Daten", systemImage: "tray", description: Text("Reservierung nicht gefunden."))
            }
        }
        .navigationTitle("Reservierung")
        .task {
            await vm.load()
            // Load equipment options for label mapping in items
            if let opts: EquipmentOptionsDTO = try? await APIClient.shared.request("equipment/options") {
                equipmentOptions = opts
            }
        }
        .refreshable { await vm.load() }
    }

    private func detailView(_ d: EquipmentReservationDetail) -> some View {
        List {
            Section("Status") {
                let s = statusLabel(d.reservationStatus)
                Text(s.text)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(s.color.opacity(0.15))
                    .clipShape(Capsule())
            }

            Section("Infos") {
                if let assetType = d.assetType, !assetType.isEmpty {
                    Text("Typ: \(assetType)")
                }
                if let reserved = d.reservedAt {
                    if let returned = d.returnedAt {
                        Text("\(formatDateTime(reserved)) – \(formatDateTime(returned))")
                    } else {
                        Text("Reserviert am \(formatDateTime(reserved))")
                    }
                }
                if let fee = d.rentalFee, !fee.isEmpty {
                    Text("Gebühr: \(fee) €")
                }
                if let notes = d.notes, !notes.isEmpty {
                    Text(notes)
                }
            }

            Section("Items") {
                if let items = d.items, !items.isEmpty {
                    ForEach(items) { it in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text((it.itemType ?? "item").capitalized)
                                if let st = it.reservationStatus, !st.isEmpty {
                                    let chip = statusLabel(st)
                                    Text(chip.text)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(chip.color.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                            }
                            if let itemId = it.itemId, itemId != 0 {
                                Text("ID: #\(itemId)").font(.footnote)
                            }
                            if let t = it.types, !t.isEmpty {
                                let tLbl = typeLabel(for: t)
                                Text("Typ: \(tLbl ?? t)").font(.footnote)
                            }
                            if let st = it.subType, !st.isEmpty {
                                let stLbl = subTypeLabel(for: it.types, sKey: st)
                                Text("Subtyp: \(stLbl ?? st)").font(.footnote)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                if let v = it.reservedAt { Text("Reserviert: \(formatDateTime(v))").font(.caption).foregroundStyle(.secondary) }
                                if let v = it.pickedUpAt { Text("Abgeholt: \(formatDateTime(v))").font(.caption).foregroundStyle(.secondary) }
                                if let v = it.returnedAt { Text("Zurück: \(formatDateTime(v))").font(.caption).foregroundStyle(.secondary) }
                                if let v = it.createdAt { Text("Erstellt: \(formatDateTime(v))").font(.caption2).foregroundStyle(.tertiary) }
                                if let v = it.updatedAt { Text("Aktualisiert: \(formatDateTime(v))").font(.caption2).foregroundStyle(.tertiary) }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } else {
                    Text("Keine Items")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func formatUnix(_ unix: Int) -> String {
        let d = Date(timeIntervalSince1970: TimeInterval(unix))
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: d)
    }
}

