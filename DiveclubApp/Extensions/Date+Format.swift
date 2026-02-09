//
//  Date+Format.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 08.02.26.
//

import Foundation

extension Date {

    var shortDate: String {
        formatted(date: .abbreviated, time: .omitted)
    }

    var longDate: String {
        formatted(date: .long, time: .omitted)
    }

    var dateTime: String {
        formatted(date: .abbreviated, time: .shortened)
    }
}
