//
//  CourseEnrollmentRequest.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

//
//  CourseEnrollmentRequest.swift
//  DiveclubApp
//
//  Created by Eckhard Becker on 07.02.26.
//

import Foundation

struct CourseEnrollmentRequest: Encodable {
    let courseId: Int
    let eventId: Int?

    enum CodingKeys: String, CodingKey {
        case courseId = "course_id"
        case eventId  = "event_id"
    }
}
