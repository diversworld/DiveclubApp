//
//  EnrollmentStore.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 08.02.26.
//

import Foundation
import Combine

@MainActor
final class EnrollmentStore: ObservableObject {
    
    static let shared = EnrollmentStore()
    
    @Published var enrollments: [Enrollment] = []
    
    private init() {}
    
    // MARK: - Aktive Kurse (Badge)
    
    var activeCount: Int {
        enrollments.filter {
            $0.isRegistered || $0.isActive
        }.count
    }
    
    // MARK: - Prüfen ob bereits angemeldet
    
    func isEnrolled(eventId: Int) -> Bool {
        enrollments.contains {
            $0.eventId == eventId &&
            ($0.isRegistered || $0.isActive)
        }
    }
    
    // MARK: - API Laden
    
    func load() async {
        do {
            let result: [Enrollment] =
                try await APIClient.shared.request("enrollments")
            
            enrollments = result
            
        } catch {
            if let apiError = error as NSError?,
               apiError.code == 404 {
                enrollments = []
            } else {
                print("Enrollment load error:", error)
            }
        }
    }
}
