//: Playground - noun: a place where people can play

import UIKit

var str = "Hello, playground"

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
    init(name: String, confidence: Double) {
        self.name = name
        self.confidence = confidence
    }
}
func removeDuplicates(users: [User]) -> [User] {
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
func buildGreeting(users: [User]) -> String {
    var ret = "Good morning"
    let unique = removeDuplicates(users: users)
    let numUsers = unique.count
    
    for (index, user) in unique.enumerated() {
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
let user1 = User(name: "user1", confidence: 0.9)
let user2 = User(name: "user2", confidence: 0.7)
let user3 = User(name: "user1", confidence: 0.3)
let user4 = User(name: "user2", confidence: 0.8)
let user5 = User(name: "user3", confidence: 0.1)

let users = [user1]// user2] // user3, user4, user5]
let uniq = removeDuplicates(users: users)
buildGreeting(users: users)
for user in uniq {
    print(user.name)
}
