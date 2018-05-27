//
//  Enrol.swift
//  GDay
//
//  Created by Erik Mai on 27/5/18.
//  Copyright © 2018 dmc. All rights reserved.
//

import Foundation
import UIKit

class Enrollment {
    var id = 0
    var image = UIImage()
    var message = ""
    var name = ""
    
    
    init(id: Int) {
        self.id = id
    }
    func errorSubmitting(message: String) {
        self.message = message
    }
    func submitted(name: String) {
        self.name = name
        message = "Submitted"
    }
    func newImage(image: UIImage) {
        self.image = image
        message = "New Image"
    }
    var unSubmitted: Bool {
        return message == "New Image"
    }
    var isSubmmited: Bool {
        return message == "Submitted"
    }
}
