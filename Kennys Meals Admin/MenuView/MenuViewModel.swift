//
//  MenuViewModel.swift
//  Kennys Meals Admin
//
//  Created by Krish on 7/25/24.
//

import Foundation
import SwiftUI
import FirebaseFirestore

class MenuViewModel: ObservableObject {
    
    @Published var canWrite = false
    @Published var searchText = String()
    @Published var menuCells = [MenuCell]()
    @Published var unsearchedMenuCells = [MenuCell]()
    @Published var isShowingDetail = false
    @Published var selectedMenu = MenuCell()
    @Published var selectedMenuCell = MenuCell()
    @Published var isAddingMeals = false
    @Published var isShowingProductionOrderDetail = false
    @Published var isShowingProductionOrders = false
    @Published var productionOrder = [MealCell: Int]()
    @Published var ingredients = [Ingredient : [Double]]()
    @Published var isShowingIngredientsView = false
    @Published var mealsProductionOrder = [Meal: Int]()
    
    func search() {
        if searchText == "" {
            menuCells = unsearchedMenuCells
        } else {
            menuCells = unsearchedMenuCells.filter({$0.docId.lowercased().contains(searchText.lowercased())})
        }
    }
    
    func extractMeal(from mealCell: MealCell, amt: Int) {
        Firestore.firestore().collection("Meals").document(mealCell.docId).getDocument { documentSnapshot, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            if let documentSnapshot = documentSnapshot {
                var instructions: [String]?
                if let instructionArray = documentSnapshot.get("instructions") {
                    if let nsinstructions = instructionArray as? NSArray, let instructionsArray = nsinstructions as? [String] {
                        instructions = instructionsArray
                    }
                }
                var portion = [Ingredient: String]()
                let portionDict = documentSnapshot.get("portion") as! [String: String]
                for portionPair in portionDict {
                    portion[Ingredient(name: portionPair.key)] = portionPair.value
                }
                self.mealsProductionOrder[Meal(docId: mealCell.docId, title: mealCell.title, subtitle: mealCell.subtitle, mealType: mealCell.mealType, nutritionFacts: NutritionFacts(), ingredients: documentSnapshot.get("ingredients") as! String, portion: portion, instructions: instructions ?? [], mealInstructions: documentSnapshot.get("mealInstructions") as! String, contains: documentSnapshot.get("contains") as! String, barcodeConversion: documentSnapshot.get("barcodeConversion") as! String, sku: mealCell.sku, image: mealCell.mealImage)] = amt
            }
        }
    }
    
    func getProductionOrder() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        Firestore.firestore().collection("Production Orders").document(tomorrow.convertToDocID).getDocument { documentSnapshot, error in
            if let error = error {
                print(error.localizedDescription)
                self.productionOrder = self.selectedMenu.mealCells
                for pair in self.productionOrder {
                    let mealCell = pair.key
                    self.extractMeal(from: mealCell, amt: pair.value)
                }
                self.totalIngredients()
                return
            }
            if let document = documentSnapshot {
                guard let data = document.data() else {
                    self.productionOrder = self.selectedMenu.mealCells
                    for pair in self.productionOrder {
                        let mealCell = pair.key
                        self.extractMeal(from: mealCell, amt: pair.value)
                    }
                    self.totalIngredients()
                    return
                }
                if data["menu"] as! String != self.selectedMenu.docId {
                    self.productionOrder = self.selectedMenu.mealCells
                    for pair in self.productionOrder {
                        let mealCell = pair.key
                        self.extractMeal(from: mealCell, amt: pair.value)
                    }
                    self.totalIngredients()
                    return
                }
                var menuMeals = [MealCell: Int]()
                let cellDict = data["meals"] as! [String: Int]
                let keys = Array(self.selectedMenu.mealCells.keys)
                for cell in cellDict {
                    if let mealCell = keys.first(where: { $0.docId == cell.key }) {
                        menuMeals[mealCell] = cell.value
                        DispatchQueue.main.async {
                            self.extractMeal(from: mealCell, amt: cell.value)
                        }
                    }
                }
                self.productionOrder = menuMeals
                print(menuMeals)
                print(self.mealsProductionOrder)
                self.totalIngredients()
            } else {
                self.productionOrder = self.selectedMenu.mealCells
                for pair in self.productionOrder {
                    let mealCell = pair.key
                    self.extractMeal(from: mealCell, amt: pair.value)
                }
                print(self.mealsProductionOrder)
                self.totalIngredients()
            }
        }
    }
    func totalIngredients() {
        let keys = Array(productionOrder.keys)
        DispatchQueue.main.async {
            for mealCell in keys {
                if self.productionOrder[mealCell]! > 0 {
                    Firestore.firestore().collection("Meals").document(mealCell.docId).getDocument { documentSnapshot, error in
                        if let error = error {
                            print(error.localizedDescription)
                            return
                        }
                        if let document = documentSnapshot {
                            guard let portions = document.get("portion") as? [String: String] else { return }
                            let portionKeys = Array(portions.keys)
                            for portion in portionKeys {
                                self.find(ingredient: portion, num: Double(self.productionOrder[mealCell]!))
                            }
                        }
                    }
                }
            }
        }
    }
    func find(ingredient: String, num: Double) {
        DispatchQueue.main.async {
            if let ing = Array(self.ingredients.keys).first(where: {$0.name == ingredient}) {
                self.ingredients[ing]![0] += num
            } else {
                Firestore.firestore().collection("Ingredients").document(ingredient).getDocument { documentSnapshot, error in
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    }
                    if let document = documentSnapshot {
                        guard let data = document.data() else { return }
                        let quantity = data["quantity"] as! Double
                        let units = data["units"] as! String
                        let ingredientsDict = data["ingredients"] as! [String: Double]
                        let preparation = data["preparation"] as! String
                        var category = data["category"] as! String
                        if category == "Carbs" {
                            category = "Carbohydrates"
                        }
                        self.ingredients[Ingredient(name: document.documentID, quantity: quantity, units: units, ingredients: ingredientsDict, preparation: preparation, category: IngredientCategory(rawValue: category)!)] = [num, 0]
                        for ingredientKey in Array(ingredientsDict.keys) {
                            let formattedIngredient = String(ingredientKey.split(separator: " (")[0])
                            self.findExist(ingredient: formattedIngredient, num: ingredientsDict[ingredientKey]!, firstNum: num)
                        }
                    }
                }
            }
        }
    }
    func findExist(ingredient: String, num: Double, firstNum: Double) {
        DispatchQueue.main.async {
            if let ing = Array(self.ingredients.keys).first(where: {$0.name == ingredient}) {
                self.ingredients[ing]![1] += num * firstNum
            } else {
                Firestore.firestore().collection("Ingredients").document(ingredient).getDocument { documentSnapshot, error in
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    }
                    if let document = documentSnapshot {
                        guard let data = document.data() else { return }
                        let quantity = data["quantity"] as! Double
                        let units = data["units"] as! String
                        let ingredientsDict = data["ingredients"] as! [String: Double]
                        let preparation = data["preparation"] as! String
                        var category = data["category"] as! String
                        if category == "Carbs" {
                            category = "Carbohydrates"
                        }
                        self.ingredients[Ingredient(name: document.documentID, quantity: quantity, units: units, ingredients: ingredientsDict, preparation: preparation, category: IngredientCategory(rawValue: category)!)] = [0, num * firstNum]
                        for ingredientKey in Array(ingredientsDict.keys) {
                            let formattedIngredient = String(ingredientKey.split(separator: " (")[0])
                            self.findExist(ingredient: formattedIngredient, num: ingredientsDict[ingredientKey]!, firstNum: firstNum)
                        }
                    }
                }
            }
        }
    }
}
