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
        NavigationStack {
            
            Group {
                if vm.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                else if let event = vm.event {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            
                            // MARK: Titel
                            Text(event.title)
                                .font(.largeTitle)
                                .bold()
                            
                            // MARK: Datum
                            Text("Start: \(event.formattedStartDate)")
                            
                            // MARK: Ort
                            if let location = event.location {
                                Label(location, systemImage: "mappin.and.ellipse")
                            }
                            
                            // MARK: Preis
                            if let price = event.price {
                                Label("\(price) €", systemImage: "eurosign.circle")
                            }
                            
                            Divider()
                            
                            // MARK: Teilnehmeranzeige
                            if let current = event.currentParticipants,
                               let max = event.maxParticipants {
                                
                                HStack {
                                    Text("Teilnehmer")
                                    Spacer()
                                    Text("\(current) / \(max)")
                                        .bold()
                                        .foregroundStyle(
                                            current >= max ? .red : .primary
                                        )
                                }
                            }
                            
                            Spacer()
                            
                            // MARK: - Anmeldung / Status

                            if vm.isAlreadyBooked {
                                
                                Label("Bereits angemeldet",
                                      systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .frame(maxWidth: .infinity)
                                    .padding(.top)
                                
                            } else {
                                
                                Button {
                                    Task {
                                        await vm.enroll()
                                    }
                                } label: {
                                    
                                    if vm.isSubmitting {
                                        ProgressView()
                                            .frame(maxWidth: .infinity)
                                    } else {
                                        Text(vm.isFull ? "Zur Warteliste" : "Jetzt anmelden")
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(vm.isSubmitting)
                                .padding(.top)
                            }
                            
                            // MARK: Fehler
                            if let error = vm.errorMessage {
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.footnote)
                            }
                        }
                        .padding()
                    }
                }
                
                else if let error = vm.errorMessage {
                    Text("Fehler: \(error)")
                }
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await vm.loadEvent(id: eventId)
            }
            .overlay(alignment: .top) {
                if vm.bookingSuccess {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Erfolgreich angemeldet")
                    }
                    .padding()
                    .background(.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding()
                    .transition(.move(edge: .top))
                }
            }
        }
    }
}
