//
//  User.swift
//  Kennys Meals Admin
//
//  Created by Krish on 6/26/24.
//

import Foundation

struct User {
    var email: String
    var uid: String
    var name: String
    var canWrite: Bool
    
    init() {
        email = ""
        uid = ""
        name = ""
        canWrite = false
    }
    
    init(name: String, email: String, uid: String, canWrite: Bool) {
        self.name = name
        self.email = email
        self.uid = uid
        self.canWrite = canWrite
    }
}
