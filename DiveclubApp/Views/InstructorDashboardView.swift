//
//  InstructorDashboardView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 08.02.26.
//

import SwiftUI

struct InstructorDashboardView: View {
    
    @StateObject private var vm = InstructorViewModel()
    
    var body: some View {
        List {
            ForEach(vm.students) { student in
                VStack(alignment: .leading, spacing: 6) {
                    Text(student.fullName)
                        .font(.headline)
                    
                    ProgressView(value: student.progressValue)
                        .tint(.green)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Instructor")
        .task {
            await vm.load()
            vm.startAutoRefresh()
        }
        .onDisappear {
            vm.stopAutoRefresh()
        }
    }
}

