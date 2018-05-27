//
//  User.swift
//  GDay
//
//  Created by Erik Mai on 25/5/18.
//  Copyright © 2018 dmc. All rights reserved.
//

import Foundation
import UIKit

class User {
    var name = ""
    var confidence = 0.0
    var enrollmentTimeStamp = Int64(0)
    init(json: [String: Any]) {
        if let subject_id = json["subject_id"] as? String {
            self.name = subject_id
        }
        if let confidence = json["confidence"] as? Double {
            self.confidence = confidence
        }
        if let timestamp = json["enrollment_timestamp"] as? Int64 {
            self.enrollmentTimeStamp = timestamp
        }
    }
    init() {
        
    }
}
