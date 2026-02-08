//
//  SectionHeader.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 08.02.26.
//

import SwiftUI

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.title3)
                .bold()
            Spacer()
        }
        .padding(.top, 8)
    }
}
