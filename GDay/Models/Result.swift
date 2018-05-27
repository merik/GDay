//
//  Result.swift
//  GDay
//
//  Created by Erik Mai on 27/5/18.
//  Copyright © 2018 dmc. All rights reserved.
//

import Foundation
import UIKit

class Result {
    var image = UIImage()
    var users = [User]()
    
    var resultOutput: String {
        if users.count == 0 {
            return "Unknown"
        }
        let uniq = getUsersWithNoDuplication()
        let numUsers = uniq.count
        var ret = ""
        for (index, user) in uniq.enumerated() {
            if index == 0 {
                ret = ret + user.name + "(" + String(format: "%.2f", user.confidence) + ")"
            } else {
                if index < numUsers - 1 {
                    ret = ret + ", " + user.name + "(" + String(format: "%.2f", user.confidence) + ")"
                } else {
                    ret = ret + " and " + user.name + "(" + String(format: "%.2f", user.confidence) + ")"
                }
            }
        }
        return ret
    }
    
    func getUsersWithNoDuplication() -> [User] {
        var ret = [User]()
        var seen = [User]()
        
        for user in users {
            if !seen.contains(where: {
                $0.name == user.name
            }) {
                ret.append(user)
                seen.append(user)
            }
        }
        return ret
    }
    func buildGreeting() -> String {
        let uniq = getUsersWithNoDuplication()
        var ret = "Good morning"
        let numUsers = uniq.count
        
        for (index, user) in uniq.enumerated() {
            if index == 0 {
                ret = ret + " " + user.name
            } else {
                if index < numUsers - 1 {
                    ret = ret + ", " + user.name
                } else {
                    ret = ret + " and " + user.name
                }
            }
        }
        return ret
    }
}
