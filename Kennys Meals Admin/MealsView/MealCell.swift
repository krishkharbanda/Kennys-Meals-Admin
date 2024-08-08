//
//  MealCell.swift
//  Kennys Meals Admin
//
//  Created by Krish on 7/9/24.
//

import Foundation
import SwiftUI
import UIKit

struct MealCell: Identifiable, Equatable, Hashable {
    var id = UUID()
    var docId: String
    var title: String
    var subtitle: String
    var cals: Int
    var carbs: Int
    var fat: Int
    var protein: Int
    var sku: Int
    var mealType: MealType
    var mealImage: UIImage?
    
    init() {
        self.id = UUID()
        self.docId = "docId"
        self.title = "title"
        self.subtitle = "subtitle"
        self.cals = 0
        self.carbs = 0
        self.fat = 0
        self.protein = 0
        self.sku = 0
        self.mealType = .all
        self.mealImage = nil
    }
    
    init(id: UUID = UUID(), docId: String, title: String, subtitle: String, cals: Int, carbs: Int, fat: Int, protein: Int, sku: Int, mealType: MealType, mealImage: UIImage? = nil) {
        self.id = id
        self.docId = docId
        self.title = title
        self.subtitle = subtitle
        self.cals = cals
        self.carbs = carbs
        self.fat = fat
        self.protein = protein
        self.sku = sku
        self.mealType = mealType
        self.mealImage = mealImage
    }
}
