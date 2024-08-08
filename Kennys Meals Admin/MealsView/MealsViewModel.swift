//
//  MealsViewModel.swift
//  Kennys Meals Admin
//
//  Created by Krish on 6/30/24.
//

import Foundation
import SwiftUI
import FirebaseFirestore

class MealsViewModel: ObservableObject {
    
    @Published var canWrite = false
    @Published var searchText = String()
    @Published var mealCells = [MealCell]()
    @Published var unsearchedMealCells = [MealCell]()
    @Published var selectedMealType: MealType = .all
    @Published var selectedSort: SortOptions = .alphabet
    @Published var selectedOrder: OrderOptions = .ascending
    @Published var isShowingDetail = false
    @Published var isShowingScanner = false
    @Published var selectedMeal = Meal()
    @Published var editedMeal = false
    @Published var viewingMealFromMenu = false
    @Published var selectedSku = Int()
    @Published var isScanError = false
    @Published var scanErrorText = String()
    @Published var selectedMealCells = [MealCell]()
    @Published var menuDocIds = ["None"]
    @Published var selectedMenuIndex = Int()
    
    func search() {
        if searchText == "" {
            mealCells = unsearchedMealCells
        } else {
            mealCells = unsearchedMealCells.filter({$0.title.lowercased().contains(searchText.lowercased()) || $0.subtitle.lowercased().contains(searchText.lowercased()) || $0.docId.lowercased().contains(searchText.lowercased())})
        }
    }
    func filter(allMeals: [MealCell]) {
        if selectedMealType == .all {
            mealCells = allMeals
        } else {
            mealCells = allMeals.filter({$0.mealType == selectedMealType})
        }
        unsearchedMealCells = mealCells
        if searchText != "" {
            search()
        }
    }
    func filterByMenu(allMeals: [MealCell], allMenus: [MenuCell]) {
        if menuDocIds[selectedMenuIndex] == "None" {
            unsearchedMealCells = allMeals
            filter(allMeals: allMeals)
        } else {
            guard let menuCell = allMenus.first(where: { $0.docId == menuDocIds[selectedMenuIndex] }) else { return }
            unsearchedMealCells = allMeals.filter({ mealCell in
                menuCell.mealCells.contains(where: { pair in
                    pair.key == mealCell
                })
            })
            filter(allMeals: unsearchedMealCells)
        }
    }
    func sort() {
        switch selectedSort {
        case .alphabet:
            mealCells = mealCells.sorted(by: {$0.title < $1.title})
        case .cals:
            mealCells = mealCells.sorted(by: {$0.cals < $1.cals})
        case .carbs:
            mealCells = mealCells.sorted(by: {$0.carbs < $1.carbs})
        case .fat:
            mealCells = mealCells.sorted(by: {$0.fat < $1.fat})
        case .protein:
            mealCells = mealCells.sorted(by: {$0.protein < $1.protein})
        }
        if selectedOrder == .descending {
            mealCells.reverse()
        }
        if searchText == "" {
            unsearchedMealCells = mealCells
        }
    }
    func getSelectedMeal(mealCell: MealCell) {
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
                let nutritionFacts = NutritionFacts(servingSize: documentSnapshot.get("servingSize") as! Int, calories: mealCell.cals, totalFat: mealCell.fat, totalFatPercentage: documentSnapshot.get("totalFatPercentage") as! Int, satFat: documentSnapshot.get("saturatedFat") as! Double, satFatPercentage: documentSnapshot.get("saturatedFatPercentage") as! Int, transFat: documentSnapshot.get("transFat") as! Double, transFatPercentage: documentSnapshot.get("transFatPercentage") as! Int, cholesterol: documentSnapshot.get("cholestrol") as! Int, cholesterolPercentage: documentSnapshot.get("cholestrolPercentage") as! Int, sodium: documentSnapshot.get("sodium") as! Int, sodiumPercentage: documentSnapshot.get("sodiumPercentage") as! Int, potassium: documentSnapshot.get("potassium") as! Int, potassiumPercentage: documentSnapshot.get("potassiumPercentage") as! Int, totalCarb: mealCell.carbs, totalCarbPercentage: documentSnapshot.get("carbohydratePercentage") as! Int, fiber: documentSnapshot.get("fiber") as! Double, fiberPercentage: documentSnapshot.get("fiberPercentage") as! Int, totalSugar: documentSnapshot.get("sugars") as! Double, addedSugars: documentSnapshot.get("addedSugars") as! Double, protein: mealCell.protein, proteinPercentage: documentSnapshot.get("proteinPercentage") as! Int, calcium: documentSnapshot.get("calcium") as! Int, calciumPercentage: documentSnapshot.get("calciumPercentage") as! Int, vitD: documentSnapshot.get("vitaminD") as! Double, vitDPercentage: documentSnapshot.get("vitaminDPercentage") as! Int, iron: documentSnapshot.get("iron") as! Double, ironPercentage: documentSnapshot.get("ironPercentage") as! Int)
                var portion = [Ingredient: String]()
                let portionDict = documentSnapshot.get("portion") as! [String: String]
                for portionPair in portionDict {
                    portion[Ingredient(name: portionPair.key)] = portionPair.value
                }
                self.selectedMeal = Meal(docId: mealCell.docId, title: mealCell.title, subtitle: mealCell.subtitle, mealType: mealCell.mealType, nutritionFacts: nutritionFacts, ingredients: documentSnapshot.get("ingredients") as! String, portion: portion, instructions: instructions ?? [], mealInstructions: documentSnapshot.get("mealInstructions") as! String, contains: documentSnapshot.get("contains") as! String, barcodeConversion: documentSnapshot.get("barcodeConversion") as! String, sku: mealCell.sku, image: mealCell.mealImage)
                self.isShowingScanner = false
                self.isShowingDetail = true
            }
        }
    }
}
