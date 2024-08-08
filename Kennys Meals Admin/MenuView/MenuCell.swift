//
//  MenuCell.swift
//  Kennys Meals Admin
//
//  Created by Krish on 7/25/24.
//

import Foundation
import SwiftUI

struct MenuCell: Identifiable, Equatable {
    var id = UUID()
    var docId: String
    var selectedMenu: Bool
    var mealCells: [MealCell: Int]
    var mealTypeCount: [MealType: Int]
    
    init() {
        self.id = UUID()
        self.docId = "docId"
        self.selectedMenu = false
        self.mealCells = [:]
        self.mealTypeCount = [:]
    }
    
    init(id: UUID = UUID(), docId: String, selectedMenu: Bool, mealCells: [MealCell : Int], mealTypeCount: [MealType : Int]) {
        self.id = id
        self.docId = docId
        self.selectedMenu = selectedMenu
        self.mealCells = mealCells
        self.mealTypeCount = mealTypeCount
    }
}
enum Day: String, CaseIterable, Equatable {
    case sunday = "Sunday"
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"
}
