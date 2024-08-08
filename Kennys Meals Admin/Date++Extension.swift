//
//  Date++Extension.swift
//  Kennys Meals Admin
//
//  Created by Krish on 8/8/24.
//

import Foundation
extension Date {
    public var convertToDocID: String {
        get {
            var formatter = DateFormatter()
            formatter.dateFormat = "MMddyyyy"
            return formatter.string(from: self)
        } set {
            var formatter = DateFormatter()
            formatter.dateFormat = "MMddyyyy"
            if let date = formatter.date(from: newValue) {
                self = date
            }
        }
    }
}
