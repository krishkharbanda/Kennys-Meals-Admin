//
//  Habitat.swift
//  Kennys Meals Admin
//
//  Created by Krish on 6/22/24.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage

class Habitat: ObservableObject {
    @Published var appScene: AppScene = .login
    @Published var user = User()
    @Published var mealCells = [MealCell]()
    @Published var menuCells = [MenuCell]()
    
    func reloadMealCells() {
        let pathReference = Storage.storage().reference(withPath: "/resizedMeals")
        Firestore.firestore().collection("Meals").getDocuments { querySnapshot, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            if let documents = querySnapshot?.documents, !documents.isEmpty {
                self.mealCells = []
                for document in documents {
                    let data = document.data()
                    pathReference.child("/\(document.documentID).png").getData(maxSize: 1 * 2000 * 2000) { imageData, error in
                        var mealImage: UIImage?
                        if let imageData = imageData {
                            mealImage = UIImage(data: imageData)
                        }
                        self.mealCells.append(MealCell(docId: document.documentID, title: data["title"] as! String, subtitle: data["subtitle"] as! String, cals: data["calories"] as! Int, carbs: data["carbohydrate"] as! Int, fat: data["totalFat"] as! Int, protein: data["protein"] as! Int, sku: data["sku"] as! Int, mealType: MealType(rawValue: data["imageTag"] as! String)!, mealImage: mealImage))
                    }
                }
            }
        }
    }
    
    func reloadMenuCells() {
        Firestore.firestore().collection("Menus").getDocuments { querySnapshot, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            if let documents = querySnapshot?.documents, !documents.isEmpty {
                self.menuCells = []
                for document in documents {
                    let data = document.data()
                    var menuMeals = [MealCell: Int]()
                    var mealTypeCount = [MealType: Int]()
                    let cellDict = data["meals"] as! [String: Int]
                    for cell in cellDict {
                        if let mealCell = self.mealCells.first(where: { $0.docId == cell.key }) {
                            menuMeals[mealCell] = cell.value
                            if let _ = mealTypeCount[mealCell.mealType] {
                                mealTypeCount[mealCell.mealType]! += 1
                            } else {
                                mealTypeCount[mealCell.mealType] = 1
                            }
                        }
                    }
                    self.menuCells.append(MenuCell(docId: document.documentID, selectedMenu: data["selectedMenu"] as! Bool, mealCells: menuMeals, mealTypeCount: mealTypeCount))
                }
            }
            if self.menuCells.count > 1 {
                if let selectedIndex = self.menuCells.firstIndex(where: { $0.selectedMenu }) {
                    self.menuCells.insert(self.menuCells[selectedIndex], at: 0)
                    self.menuCells.remove(at: selectedIndex+1)
                }
            }
        }
    }
    
    func delete(menuCell: MenuCell) -> Bool {
        if let index = menuCells.firstIndex(of: menuCell) {
            Firestore.firestore().collection("Menus").document(menuCell.docId).delete()
            print("Deleted")
            menuCells.remove(at: index)
            return true
        }
        return false
    }
}
