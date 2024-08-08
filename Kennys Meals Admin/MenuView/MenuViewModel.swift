//
//  MenuViewModel.swift
//  Kennys Meals Admin
//
//  Created by Krish on 7/25/24.
//

import Foundation
import SwiftUI

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
    
    func search() {
        if searchText == "" {
            menuCells = unsearchedMenuCells
        } else {
            menuCells = unsearchedMenuCells.filter({$0.docId.lowercased().contains(searchText.lowercased())})
        }
    }
}
