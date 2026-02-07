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
            List(vm.events) { event in
                NavigationLink {
                    EventDetailView(eventId: event.id)
                } label: {
                    VStack(alignment: .leading) {
                        Text(event.title)
                            .font(.headline)
                        Text(event.formattedStartDate)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Events")
            .task {
                await vm.loadEvents()
            }
        }
    }
}

#Preview {
    EventsView()
}
