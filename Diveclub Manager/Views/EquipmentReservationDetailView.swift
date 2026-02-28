//
//  EquipmentReservationDetailView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 10.02.26.
//

import SwiftUI

struct EquipmentReservationDetailView: View {

    @StateObject private var vm: EquipmentReservationDetailViewModel
    @State private var isNotesExpanded = false   // ✅ NEU

    init(reservationId: Int) {
        _vm = StateObject(wrappedValue: EquipmentReservationDetailViewModel(reservationId: reservationId))
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
        .task { await vm.load() }
        .refreshable { await vm.load() }
    }

    private func detailView(_ d: ReservationDetailDTO) -> some View {
        List {
            Section("Status") {
                let s = statusLabel(d.reservationStatus)

                HStack {
                    Text((d.title?.isEmpty == false) ? d.title! : "Reservierung #\(d.id)")
                        .font(.headline)
                    Spacer()
                    Text(s.text)
                        .font(.body)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(s.color.opacity(0.15))
                        .clipShape(Capsule())
                }
            }

            Section("Infos") {
                if let reserved = d.reservedAt {
                    if let returned = d.returnedAt {
                        Text("Reserviert am: \(formatDateTime(reserved)) – Zurückgegeben am: \(formatDateTime(returned))")
                    } else {
                        Text("Reserviert am \(formatDateTime(reserved))")
                    }
                }
                if let fee = d.rentalFee, !fee.isEmpty {
                    Text("Gebühr: \(fee) €")
                }
                if let notes = d.notes, !notes.isEmpty {
                    ExpandableHTMLText(
                        html: notes,
                        textStyle: .body,
                        collapsedLineLimit: 6,
                        isExpanded: $isNotesExpanded          // ✅ NEU
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Section("Items") {
                let items = d.items ?? []

                if !items.isEmpty {
                    ForEach(items, id: \.id) { it in
                        VStack(alignment: .leading, spacing: 6) {

                            HStack {
                                Text(itemTypeLabel(it.itemType))
                                    .font(.headline)

                                Spacer()

                                let st = statusLabel(it.reservationStatus ?? d.reservationStatus)
                                Text(st.text)
                                    .font(.body)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(st.color.opacity(0.15))
                                    .clipShape(Capsule())
                            }

                            if let itemId = it.itemId, itemId != 0 {
                                Text("Item-ID: #\(itemId)")
                                    .font(.body)
                                    .foregroundStyle(.secondary)

                                // ✅ Klartext-Details aus Katalog + Options
                                catalogDetailsView(itemType: it.itemType, itemId: itemId, item: it)
                            }

                            // ✅ Equipment-Typ/Subtyp Klartext (oder fallback auf Keys)
                            if isEquipment(it.itemType) {
                                if let line = vm.prettyTypeLineWithFallback(types: it.types, subType: it.subType) {
                                    Text(line)
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            if let n = it.notes, !n.isEmpty {
                                Text(n)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                if let v = it.reservedAt { Text("Reserviert: \(formatDateTime(v))").font(.body).foregroundStyle(.tertiary) }
                                if let v = it.pickedUpAt { Text("Abgeholt: \(formatDateTime(v))").font(.body).foregroundStyle(.tertiary) }
                                if let v = it.returnedAt { Text("Zurück: \(formatDateTime(v))").font(.body).foregroundStyle(.tertiary) }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } else {
                    ContentUnavailableView("Keine Items", systemImage: "tray", description: Text("Die Detail-API liefert keine Items."))
                }
            }
        }
    }

    // MARK: - Catalog Details (über VM Lookups + Options)

    @ViewBuilder
    private func catalogDetailsView(itemType: String?, itemId: Int, item: ReservationDetailItemDTO) -> some View {
        let raw = (itemType ?? "").lowercased()

        if raw.contains("tank") {
            if let t = vm.tanksById[itemId] {
                VStack(alignment: .leading, spacing: 4) {
                    let inv = (t.title?.isEmpty == false) ? t.title! : "Flasche #\(t.id)"
                    Text("Inventar: \(inv)")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    if let sub = t.displaySubtitle, !sub.isEmpty {
                        Text(sub).font(.body).foregroundStyle(.secondary)
                    }
                }
            }

        } else if raw.contains("regulator") {
            if let r = vm.regsById[itemId] {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Inventar: \(r.displayTitle)")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    // ✅ Klartext-Reglerdetails (Options: Hersteller + Modellnamen)
                    let lines = vm.prettyRegulatorDetails(r)
                    ForEach(lines, id: \.self) { line in
                        Text(line).font(.body).foregroundStyle(.secondary)
                    }
                }
            } else {
                // Fallback: zumindest Modelle aus dem Item (wenn geliefert)
                let m1 = item.regModel1st
                let m2p = item.regModel2ndPri
                let m2s = item.regModel2ndSec
                if (m1?.isEmpty == false) || (m2p?.isEmpty == false) || (m2s?.isEmpty == false) {
                    VStack(alignment: .leading, spacing: 4) {
                        if let v = m1, !v.isEmpty { Text("Modell 1. Stufe: \(v)").font(.body).foregroundStyle(.secondary) }
                        if let v = m2p, !v.isEmpty { Text("Modell 2. Stufe (prim): \(v)").font(.body).foregroundStyle(.secondary) }
                        if let v = m2s, !v.isEmpty { Text("Modell 2. Stufe (sec): \(v)").font(.body).foregroundStyle(.secondary) }
                    }
                }
            }

        } else if raw.contains("equipment") {
            if let e = vm.eqById[itemId] {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Inventar: \(e.displayTitle)")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    // ✅ Klartext-Equipmentdetails (Options: Typ/Subtyp/Hersteller/Größe)
                    let lines = vm.prettyEquipmentDetails(e)
                    ForEach(lines, id: \.self) { line in
                        Text(line).font(.body).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func isEquipment(_ raw: String?) -> Bool {
        (raw ?? "").lowercased().contains("equipment")
    }

    private func itemTypeLabel(_ raw: String?) -> String {
        let s = (raw ?? "").lowercased()
        if s.contains("regulator") { return "Atemregler" }
        if s.contains("tank") { return "Flasche" }
        if s.contains("equipment") { return "Equipment" }
        return (raw?.isEmpty == false) ? raw! : "Item"
    }

    private func statusLabel(_ raw: String?) -> (text: String, color: Color) {
        let key = (raw ?? "").lowercased()
        switch key {
        case "pending", "open": return ("Offen", .orange)
        case "reserved": return ("Reserviert", .orange)
        case "confirmed", "approved": return ("Bestätigt", .blue)
        case "picked_up", "pickedup", "active": return ("Ausgegeben", .purple)
        case "returned", "closed": return ("Zurückgegeben", .green)
        case "cancelled", "canceled": return ("Storniert", .red)
        default:
            return (raw == nil ? "Unbekannt (nil)" : "Unbekannt (\(raw!))", .secondary)
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
}
