//
//  MyCoursesViewModel.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import Foundation
import Combine

@MainActor
final class MyCoursesViewModel: ObservableObject {
    
    @Published var enrollments: [Enrollment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func load() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result: [Enrollment] =
                try await APIClient.shared.request("enrollments")
            
            enrollments = result
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
