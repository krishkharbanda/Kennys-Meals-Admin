//
//  Int++Extension.swift
//  Kennys Meals Admin
//
//  Created by Krish on 7/17/24.
//

import Foundation

extension Int {
    public var toString: String {
        get {
            return String(self)
        }
        set {
            self = Int(newValue) ?? 0
        }
    }
}
