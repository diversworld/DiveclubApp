import Foundation

struct EquipmentOptionsDTO: Codable {
    let types: [String: TypeEntry]
    let manufacturers: [String: String]
    let sizes: [String: String]

    struct TypeEntry: Codable {
        let name: String
        let subtypes: [String: String]
    }
}
