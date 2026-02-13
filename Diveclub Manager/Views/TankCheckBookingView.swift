//
//  TankCheckBookingView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 09.02.26.
//

//
//  TankCheckBookingView.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 09.02.26.
//

import SwiftUI

/// Legacy-/Alias-View: ältere Navigationen zeigen ggf. noch auf TankCheckBookingView.
/// Wir leiten einfach auf die neue Detail-View weiter.
struct TankCheckBookingView: View {

    let proposalId: Int

    var body: some View {
        TankCheckDetailView(proposalId: proposalId)
    }
}
