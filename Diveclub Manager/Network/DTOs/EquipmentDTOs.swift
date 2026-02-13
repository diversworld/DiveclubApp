//
//  EquipmentDTOs.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 10.02.26.
//

import Foundation

// /api/equipment
struct EquipmentDTO: Decodable, Identifiable, Equatable {
    let id: Int
    let title: String?
    let status: String?
    let rentalFee: String?
    let manufacturer: Int?
    let model: String?
    let color: String?
    let size: Int?
    let serialNumber: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id, title, status, manufacturer, model, color, size, serialNumber, notes
        case rentalFee
    }
}

// /api/tanks
struct TankDTO: Decodable, Identifiable, Equatable {
    let id: Int
    let title: String?
    let serialNumber: String?
    let manufacturer: String?
    let bazNumber: String?
    let size: String?
    let status: String?
    let rentalFee: String?
    let lastCheckDate: Int?
    let nextCheckDate: Int?

    enum CodingKeys: String, CodingKey {
        case id, title, serialNumber, manufacturer, bazNumber, size, status, rentalFee, lastCheckDate, nextCheckDate
    }
}

// /api/regulators
struct RegulatorDTO: Decodable, Identifiable, Equatable {
    let id: Int
    let title: String?
    let status: String?
    let rentalFee: String?
    let manufacturer: String?
    let serialNumber1st: String?
    let serialNumber2ndPri: String?
    let serialNumber2ndSec: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id, title, status, rentalFee, manufacturer, serialNumber1st, serialNumber2ndPri, serialNumber2ndSec, notes
    }
}

// Mapping -> EquipmentAsset
extension EquipmentDTO {
    func toAsset() -> EquipmentAsset {
        let detailsParts: [String] = [
            model?.isEmpty == false ? "Modell: \(model!)" : nil,
            color?.isEmpty == false ? "Farbe: \(color!)" : nil,
            size != nil ? "Größe: \(size!)" : nil,
            notes?.isEmpty == false ? notes : nil
        ].compactMap { $0 }

        return EquipmentAsset(
            id: id,
            type: .equipment,
            title: (title?.isEmpty == false ? title! : "Ausrüstung #\(id)"),
            status: status,
            fee: rentalFee,
            //lastInspectionAt: nil,
            details: detailsParts.isEmpty ? nil : detailsParts.joined(separator: "\n")
        )
    }
}

extension TankDTO {
    func toAsset() -> EquipmentAsset {
        let name = [
            title?.isEmpty == false ? title : nil,
            serialNumber?.isEmpty == false ? "SN \(serialNumber!)" : nil,
            size?.isEmpty == false ? "\(size!) L" : nil
        ].compactMap { $0 }.joined(separator: " · ")

        let details = [
            manufacturer?.isEmpty == false ? "Hersteller: \(manufacturer!)" : nil,
            bazNumber?.isEmpty == false ? "BAZ: \(bazNumber!)" : nil
        ].compactMap { $0 }.joined(separator: "\n")

        return EquipmentAsset(
            id: id,
            type: .tank,
            title: name.isEmpty ? "Flasche #\(id)" : name,
            status: status,
            fee: rentalFee,
            //lastInspectionAt: nextCheckDate, // optional: du kannst auch lastCheckDate nutzen
            details: details.isEmpty ? nil : details
        )
    }
}

extension RegulatorDTO {
    func toAsset() -> EquipmentAsset {
        let details = [
            serialNumber1st?.isEmpty == false ? "1. Stufe: \(serialNumber1st!)" : nil,
            serialNumber2ndPri?.isEmpty == false ? "2. Stufe (prim): \(serialNumber2ndPri!)" : nil,
            serialNumber2ndSec?.isEmpty == false ? "2. Stufe (sec): \(serialNumber2ndSec!)" : nil,
            notes?.isEmpty == false ? notes : nil
        ].compactMap { $0 }.joined(separator: "\n")

        return EquipmentAsset(
            id: id,
            type: .regulator,
            title: (title?.isEmpty == false ? title! : "Regler #\(id)"),
            status: status,
            fee: rentalFee,
            //lastInspectionAt: nil,
            details: details.isEmpty ? nil : details
        )
    }
}
