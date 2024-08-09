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
    
    func search() {
        if searchText == "" {
            menuCells = unsearchedMenuCells
        } else {
            menuCells = unsearchedMenuCells.filter({$0.docId.lowercased().contains(searchText.lowercased())})
        }
    }
    func getProductionOrder() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        Firestore.firestore().collection("Production Orders").document(tomorrow.convertToDocID).getDocument { documentSnapshot, error in
            if let error = error {
                print(error.localizedDescription)
                self.productionOrder = self.selectedMenu.mealCells
                return
            }
            if let document = documentSnapshot {
                guard let data = document.data() else { return }
                var menuMeals = [MealCell: Int]()
                let cellDict = data["meals"] as! [String: Int]
                let keys = Array(self.selectedMenu.mealCells.keys)
                for cell in cellDict {
                    if let mealCell = keys.first(where: { $0.docId == cell.key }) {
                        menuMeals[mealCell] = cell.value
                    }
                }
                self.productionOrder = menuMeals
            }
        }
    }
    
}
