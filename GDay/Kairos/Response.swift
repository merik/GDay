//
//  Response.swift
//  GDay
//
//  Created by Erik Mai on 25/5/18.
//  Copyright © 2018 dmc. All rights reserved.
//

import Foundation


enum Response<T> {
    case success(T)
    case error(String)
}
