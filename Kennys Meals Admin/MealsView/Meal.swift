//
//  Meal.swift
//  Kennys Meals Admin
//
//  Created by Krish on 6/30/24.
//

import Foundation
import SwiftUI
import UIKit

struct Meal: Equatable {
    
    static func == (lhs: Meal, rhs: Meal) -> Bool {
        return (lhs.docId == rhs.docId) && (lhs.title == rhs.subtitle) && (lhs.subtitle == rhs.subtitle) && (lhs.mealType == rhs.mealType) && (lhs.nutritionFacts == rhs.nutritionFacts) && (lhs.ingredients == rhs.ingredients) && (lhs.portion == rhs.portion) && (lhs.instructions == rhs.instructions) && (lhs.mealInstructions == rhs.mealInstructions) && (lhs.contains == rhs.contains) && (lhs.sku == rhs.sku) && (lhs.image == rhs.image)
    }
    
    var docId: String
    var title: String
    var subtitle: String
    var mealType: MealType
    var nutritionFacts: NutritionFacts
    var ingredients: String
    var portion: [Ingredient: String]
    var instructions: [String]
    var mealInstructions: String
    var contains: String
    var barcodeConversion: String
    var sku: Int
    var image: UIImage?
    
    init() {
        self.docId = "docId"
        self.title = "title"
        self.subtitle = "subtitle"
        self.mealType = .all
        self.nutritionFacts = NutritionFacts(servingSize: 0, calories: 0, totalFat: 0, totalFatPercentage: 0, satFat: 0, satFatPercentage: 0, transFat: 0, transFatPercentage: 0, cholesterol: 0, cholesterolPercentage: 0, sodium: 0, sodiumPercentage: 0, potassium: 0, potassiumPercentage: 0, totalCarb: 0, totalCarbPercentage: 0, fiber: 0, fiberPercentage: 0, totalSugar: 0, addedSugars: 0, protein: 0, proteinPercentage: 0, calcium: 0, calciumPercentage: 0, vitD: 0, vitDPercentage: 0, iron: 0, ironPercentage: 0)
        self.ingredients = "ingredients"
        self.portion = [:]
        self.instructions = []
        self.mealInstructions = "mealInstructions"
        self.contains = "contains"
        self.barcodeConversion = "barcodeConversion"
        self.sku = 0
    }
    
    init(docId: String, title: String, subtitle: String, mealType: MealType, nutritionFacts: NutritionFacts, ingredients: String, portion: [Ingredient : String], instructions: [String], mealInstructions: String, contains: String, barcodeConversion: String, sku: Int, image: UIImage?) {
        self.docId = docId
        self.title = title
        self.subtitle = subtitle
        self.mealType = mealType
        self.nutritionFacts = nutritionFacts
        self.ingredients = ingredients
        self.portion = portion
        self.instructions = instructions
        self.mealInstructions = mealInstructions
        self.contains = contains
        self.barcodeConversion = barcodeConversion
        self.sku = sku
        self.image = image
    }
}
struct NutritionFacts: Equatable {
    var servingSize: Int
    var calories: Int
    var totalFat: Int
    var totalFatPercentage: Int
    var satFat: Double
    var satFatPercentage: Int
    var transFat: Double
    var transFatPercentage: Int
    var cholesterol: Int
    var cholesterolPercentage: Int
    var sodium: Int
    var sodiumPercentage: Int
    var potassium: Int
    var potassiumPercentage: Int
    var totalCarb: Int
    var totalCarbPercentage: Int
    var fiber: Double
    var fiberPercentage: Int
    var totalSugar: Double
    var addedSugars: Double
    var protein: Int
    var proteinPercentage: Int
    var calcium: Int
    var calciumPercentage: Int
    var vitD: Double
    var vitDPercentage: Int
    var iron: Double
    var ironPercentage: Int
}
struct Ingredient: Hashable, Equatable {
    var name: String
}
enum MealType: String, CaseIterable, Identifiable {
    var id: Self {
        return self
    }
    case all = "All"
    case chicken = "Chicken"
    case turkey = "Turkey"
    case seafood = "Seafood"
    case pork = "Pork"
    case beef = "Beef"
    case lowCarb = "Low Carb"
    case vegan = "Vegan"
    case breakfast = "Breakfast"
    
    var color: SwiftUI.Color {
        switch self {
        case .chicken:
            return .yellow
        case .turkey:
            return .yellow
        case .seafood:
            return .blue
        case .pork:
            return .red
        case .beef:
            return .red
        case .lowCarb:
            return .green
        case .vegan:
            return .pink
        case .breakfast:
            return .orange
        case .all:
            return .gray
        }
    }
}
struct NutrientDVs {
    static var fat = 70
    static var satFat = 20
    static var transFat = 300
    static var cholesterol = 300
    static var carbs = 300
    static var fiber = 28
    static var protein = 50
    static var vitD = 20
    static var calcium = 1300
    static var iron = 18
    static var potassium = 4700
    static var sodium = 2300
    
    static func returnValue(field: String) -> Int {
        switch field {
        case "totalFat":
            return fat
        case "saturatedFat":
            return satFat
        case "cholestrol":
            return cholesterol
        case "carbohydrate":
            return carbs
        case "fiber":
            return fiber
        case "protein":
            return protein
        case "vitaminD":
            return vitD
        case "calcium":
            return calcium
        case "iron":
            return iron
        case "potassium":
            return potassium
        case "sodium":
            return sodium
        default:
            return 0
        }
    }
}
