//
//  StudentProgressRow.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 08.02.26.
//

import SwiftUI

struct StudentProgressRow: View {
    
    let student: Student
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            HStack {
                Text(student.fullName)
                    .font(.headline)
                
                Spacer()
                
                Text("\(Int(student.progressValue * 100))%")
                    .font(.caption)
                    .bold()
            }
            
            ProgressView(value: student.progressValue)
                .tint(.green)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
