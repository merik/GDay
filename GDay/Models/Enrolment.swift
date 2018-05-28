//
//  Enrol.swift
//  GDay
//
//  Created by Erik Mai on 27/5/18.
//  Copyright © 2018 dmc. All rights reserved.
//

import Foundation
import UIKit

enum EnrolmentStatus {
    case notSubmitted
    case errorSubmitting
    case submitted
}
class Enrolment {
    var id = 0
    var image = UIImage()
    var message = ""
    var name = ""
    
    var status = EnrolmentStatus.notSubmitted
    
    init(id: Int) {
        self.id = id
    }
    func errorSubmitting(message: String) {
        status = .errorSubmitting
        self.message = message
    }
    func submitted(name: String) {
        self.name = name
        status = .submitted
        message = "Submitted"
    }
    func newWith(image: UIImage) {
        status = .notSubmitted
        self.image = image
        message = "New Image"
    }
    var notSubmitted: Bool {
        return status != .submitted
    }
    var submitted: Bool {
        return status == .submitted
    }
}
