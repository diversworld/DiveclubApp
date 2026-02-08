//
//  InstructorViewModel.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 08.02.26.
//

import Foundation
import Combine

@MainActor
final class InstructorViewModel: ObservableObject {
    
    @Published var students: [InstructorStudent] = []
    @Published var errorMessage: String?
    
    private var timer: AnyCancellable?
    
    func startAutoRefresh() {
        timer = Timer.publish(every: 15, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                Task { await self.load() }
            }
    }
    
    func stopAutoRefresh() {
        timer?.cancel()
    }
    
    func load() async {
        do {
            students = try await APIClient.shared.request("progress/instructor")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
