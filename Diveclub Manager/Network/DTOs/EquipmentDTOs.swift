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
    let manufacturer: String?
    let model: String?
    let color: String?
    let size: Int?
    let serialNumber: String?
    let notes: String?
    let types: String?
    let sub_type: String?
    let type_label: String?
    let sub_type_label: String?
    let manufacturer_label: String?
    let size_label: String?
    let status_label: String?

    // Normalized category keys and IDs for stable filtering/selection
    var typeKey: String? {
        guard let types else { return nil }
        return types.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    var subTypeKey: String? {
        guard let sub_type else { return nil }
        return sub_type.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    var typeID: Int? {
        guard let key = typeKey else { return nil }
        return Int(key)
    }
    var subTypeID: Int? {
        guard let key = subTypeKey else { return nil }
        return Int(key)
    }

    // Display helpers for selection lists
    var displayTitle: String {
        if let t = title, !t.isEmpty { return t }
        return "Ausrüstung #\(id)"
    }
    var displaySubtitle: String? {
        let parts: [String] = [
            type_label?.isEmpty == false ? type_label! : nil,
            sub_type_label?.isEmpty == false ? sub_type_label! : nil,
            manufacturer_label?.isEmpty == false ? "Hersteller: \(manufacturer_label!)" : nil,
            size_label?.isEmpty == false ? "Größe: \(size_label!)" : nil,
            model?.isEmpty == false ? "Modell: \(model!)" : nil,
            color?.isEmpty == false ? "Farbe: \(color!)" : nil,
            notes?.isEmpty == false ? notes : nil
        ].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: "\n")
    }

    enum CodingKeys: String, CodingKey {
        case id, title, status, model, color, size, notes
        case rentalFee = "rentalFee"
        case manufacturer = "manufacturer"
        case serialNumber = "serialNumber"
        case types
        case sub_type
        case type_label
        case sub_type_label
        case manufacturer_label
        case size_label
        case status_label
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        title = try c.decodeIfPresent(String.self, forKey: .title)
        status = try c.decodeIfPresent(String.self, forKey: .status)
        model = try c.decodeIfPresent(String.self, forKey: .model)
        color = try c.decodeIfPresent(String.self, forKey: .color)
        size = try c.decodeIfPresent(Int.self, forKey: .size)
        notes = try c.decodeIfPresent(String.self, forKey: .notes)
        serialNumber = try c.decodeIfPresent(String.self, forKey: .serialNumber)
        // rentalFee can be number or string
        if let num = try? c.decode(Double.self, forKey: .rentalFee) { rentalFee = String(num) }
        else { rentalFee = try c.decodeIfPresent(String.self, forKey: .rentalFee) }
        // manufacturer can be number or string; store as string for display
        if let num = try? c.decode(Int.self, forKey: .manufacturer) { manufacturer = String(num) }
        else { manufacturer = try c.decodeIfPresent(String.self, forKey: .manufacturer) }

        // types/sub_type can be number or string -> store as string
        if let tNum = try? c.decode(Int.self, forKey: .types) { types = String(tNum) }
        else { types = try c.decodeIfPresent(String.self, forKey: .types) }
        if let stNum = try? c.decode(Int.self, forKey: .sub_type) { sub_type = String(stNum) }
        else { sub_type = try c.decodeIfPresent(String.self, forKey: .sub_type) }

        type_label = try c.decodeIfPresent(String.self, forKey: .type_label)
        sub_type_label = try c.decodeIfPresent(String.self, forKey: .sub_type_label)
        manufacturer_label = try c.decodeIfPresent(String.self, forKey: .manufacturer_label)
        size_label = try c.decodeIfPresent(String.self, forKey: .size_label)
        status_label = try c.decodeIfPresent(String.self, forKey: .status_label)
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

    // Display helpers for selection lists
    var displayTitle: String {
        let name = [
            title?.isEmpty == false ? title : nil,
            serialNumber?.isEmpty == false ? "SN \(serialNumber!)" : nil,
            size?.isEmpty == false ? "\(size!) L" : nil
        ].compactMap { $0 }.joined(separator: " · ")
        return name.isEmpty ? "Flasche #\(id)" : name
    }
    var displaySubtitle: String? {
        let details = [
            manufacturer?.isEmpty == false ? "Hersteller: \(manufacturer!)" : nil,
            bazNumber?.isEmpty == false ? "BAZ: \(bazNumber!)" : nil
        ].compactMap { $0 }.joined(separator: "\n")
        return details.isEmpty ? nil : details
    }

    enum CodingKeys: String, CodingKey {
        case id, title, serialNumber, manufacturer, bazNumber, size, status, rentalFee, lastCheckDate, nextCheckDate
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        title = try c.decodeIfPresent(String.self, forKey: .title)
        serialNumber = try c.decodeIfPresent(String.self, forKey: .serialNumber)
        manufacturer = try c.decodeIfPresent(String.self, forKey: .manufacturer)
        bazNumber = try c.decodeIfPresent(String.self, forKey: .bazNumber)
        size = try c.decodeIfPresent(String.self, forKey: .size)
        status = try c.decodeIfPresent(String.self, forKey: .status)
        if let num = try? c.decode(Double.self, forKey: .rentalFee) { rentalFee = String(num) }
        else { rentalFee = try c.decodeIfPresent(String.self, forKey: .rentalFee) }
        lastCheckDate = try c.decodeIfPresent(Int.self, forKey: .lastCheckDate)
        nextCheckDate = try c.decodeIfPresent(Int.self, forKey: .nextCheckDate)
    }
}

// /api/regulators
struct RegulatorDTO: Decodable, Identifiable, Equatable {
    let id: Int
    let title: String?
    let status: String?
    let rentalFee: String?
    let manufacturer: String?
    let regModel1st: String?
    let regModel2ndPri: String?
    let regModel2ndSec: String?
    let serialNumber1st: String?
    let serialNumber2ndPri: String?
    let serialNumber2ndSec: String?
    let notes: String?

    // Display helpers for selection lists
    var displayTitle: String {
        if let t = title, !t.isEmpty { return t }
        return "Regler #\(id)"
    }
    var displaySubtitle: String? {
        let details = [
            serialNumber1st?.isEmpty == false ? "1. Stufe: \(serialNumber1st!)" : nil,
            regModel1st?.isEmpty == false ? "Modell 1. Stufe: \(regModel1st!)" : nil,
            serialNumber2ndPri?.isEmpty == false ? "2. Stufe (prim): \(serialNumber2ndPri!)" : nil,
            regModel2ndPri?.isEmpty == false ? "Modell 2. Stufe (prim): \(regModel2ndPri!)" : nil,
            serialNumber2ndSec?.isEmpty == false ? "2. Stufe (sec): \(serialNumber2ndSec!)" : nil,
            regModel2ndSec?.isEmpty == false ? "Modell 2. Stufe (sec): \(regModel2ndSec!)" : nil,
            notes?.isEmpty == false ? notes : nil
        ].compactMap { $0 }.joined(separator: "\n")
        return details.isEmpty ? nil : details
    }

    enum CodingKeys: String, CodingKey {
        case id, title, status, rentalFee, manufacturer, serialNumber1st, serialNumber2ndPri, serialNumber2ndSec, notes, regModel1st, regModel2ndPri, regModel2ndSec
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        title = try c.decodeIfPresent(String.self, forKey: .title)
        status = try c.decodeIfPresent(String.self, forKey: .status)
        if let num = try? c.decode(Double.self, forKey: .rentalFee) { rentalFee = String(num) }
        else { rentalFee = try c.decodeIfPresent(String.self, forKey: .rentalFee) }
        if let manNum = try? c.decode(Int.self, forKey: .manufacturer) { manufacturer = String(manNum) }
        else { manufacturer = try c.decodeIfPresent(String.self, forKey: .manufacturer) }
        serialNumber1st = try c.decodeIfPresent(String.self, forKey: .serialNumber1st)
        serialNumber2ndPri = try c.decodeIfPresent(String.self, forKey: .serialNumber2ndPri)
        serialNumber2ndSec = try c.decodeIfPresent(String.self, forKey: .serialNumber2ndSec)
        regModel1st = try c.decodeIfPresent(String.self, forKey: .regModel1st)
        regModel2ndPri = try c.decodeIfPresent(String.self, forKey: .regModel2ndPri)
        regModel2ndSec = try c.decodeIfPresent(String.self, forKey: .regModel2ndSec)
        notes = try c.decodeIfPresent(String.self, forKey: .notes)
    }
}

// Mapping -> EquipmentAsset
extension EquipmentDTO {
    func toAsset() -> EquipmentAsset {
        let detailsParts: [String] = [
            type_label?.isEmpty == false ? type_label! : nil,
            sub_type_label?.isEmpty == false ? sub_type_label! : nil,
            manufacturer_label?.isEmpty == false ? "Hersteller: \(manufacturer_label!)" : nil,
            size_label?.isEmpty == false ? "Größe: \(size_label!)" : nil,
            model?.isEmpty == false ? "Modell: \(model!)" : nil,
            color?.isEmpty == false ? "Farbe: \(color!)" : nil,
            notes?.isEmpty == false ? notes : nil
        ].compactMap { $0 }

        return EquipmentAsset(
            id: id,
            type: .equipment,
            title: displayTitle,
            status: status,
            fee: rentalFee,
            details: detailsParts.isEmpty ? nil : detailsParts.joined(separator: "\n")
        )
    }
}

extension TankDTO {
    func toAsset() -> EquipmentAsset {
        return EquipmentAsset(
            id: id,
            type: .tank,
            title: displayTitle,
            status: status,
            fee: rentalFee,
            details: displaySubtitle
        )
    }
}

extension RegulatorDTO {
    func toAsset() -> EquipmentAsset {
        return EquipmentAsset(
            id: id,
            type: .regulator,
            title: displayTitle,
            status: status,
            fee: rentalFee,
            details: displaySubtitle
        )
    }
}

