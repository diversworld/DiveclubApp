//
//  MyCoursesView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import SwiftUI

struct MyCoursesView: View {
    
    @StateObject private var vm = MyCoursesViewModel()
    
    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            else if vm.enrollments.isEmpty {
                ContentUnavailableView(
                    "Keine Kurse",
                    systemImage: "graduationcap",
                    description: Text("Du bist aktuell in keinem Kurs angemeldet.")
                )
            }
            
            else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(vm.enrollments) { enrollment in
                            EnrollmentRow(enrollment: enrollment)
                        }
                    }
                    .padding()
                }
                .refreshable {
                    await vm.load()   // ✅ WICHTIG: MIT KLAMMERN
                }
            }
        }
        .navigationTitle("Meine Kurse")
        .task {
            await vm.load()        // ✅ WICHTIG: MIT KLAMMERN
        }
    }
}
