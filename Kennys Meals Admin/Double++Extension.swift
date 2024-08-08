//
//  Double++Extension.swift
//  Kennys Meals Admin
//
//  Created by Krish on 7/13/24.
//

import Foundation

extension Double {
    func forTrailingZero() -> String {
        return String(format: "%g", self)
    }
    public var toString: String {
        get {
            return self.forTrailingZero()
        } set {
            self = Double(newValue) ?? 0
        }
    }
}
