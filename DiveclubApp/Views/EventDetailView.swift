//
//  EventDetailView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import SwiftUI

struct EventDetailView: View {
    
    let eventId: Int
    @StateObject private var vm = EventDetailViewModel()
    
    var body: some View {
        ZStack {
            
            if vm.isLoading {
                ProgressView()
                
            } else if let event = vm.event {
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        
                        Text(event.title)
                            .font(.largeTitle)
                            .bold()
                        
                        Text("Start: \(event.formattedStartDate)")
                        
                        if let location = event.location {
                            Label(location, systemImage: "mappin.and.ellipse")
                        }
                        
                        if let price = event.price {
                            Label("\(price) €", systemImage: "eurosign.circle")
                        }
                        
                        Button {
                            Task {
                                do {
                                    try await vm.createReservation(for: eventId)
                                    print("Reservierung erfolgreich")
                                } catch {
                                    print("Fehler bei Reservierung:", error)
                                }
                            }
                        } label: {
                            if vm.isSubmitting {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else {
                                Label("Jetzt buchen", systemImage: "checkmark.circle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top)
                        .disabled(vm.isSubmitting)
                    }
                    .padding()
                }
                
            } else if let error = vm.errorMessage {
                Text("Fehler: \(error)")
            }
        }
        .navigationTitle("Details")
        .task {
            await vm.loadEvent(id: eventId)
        }
    }
}
