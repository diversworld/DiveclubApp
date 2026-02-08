//
//  EventView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import SwiftUI

struct EventsView: View {
    
    @StateObject private var vm = EventsViewModel()
    
    var body: some View {
        NavigationStack {
            
            Group {
                if vm.isLoading {
                    ProgressView()
                }
                
                else if let error = vm.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                }
                
                else {
                    List(vm.events) { event in
                        NavigationLink {
                            EventDetailView(eventId: event.id)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(event.title)
                                    .font(.headline)
                                
                                Text(event.formattedStartDate)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .refreshable {
                        await vm.load()
                    }
                }
            }
            .navigationTitle("Events")
            .task {
                await vm.load()
            }
        }
    }
}
