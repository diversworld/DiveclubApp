//
//  EventsViewModel.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import Foundation
import Combine

@MainActor
final class EventsViewModel: ObservableObject {
    
    @Published var events: [Event] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func load() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let loadedEvents: [Event] =
                try await APIClient.shared.request("events")
            
            self.events = loadedEvents
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
