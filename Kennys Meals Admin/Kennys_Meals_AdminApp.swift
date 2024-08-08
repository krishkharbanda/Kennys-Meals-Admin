//
//  Kennys_Meals_AdminApp.swift
//  Kennys Meals Admin
//
//  Created by Krish on 6/16/24.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

@main
struct Kennys_Meals_AdminApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var habitat = Habitat()
    
    var body: some Scene {
        WindowGroup {
            HabitatView()
                .environmentObject(habitat)
                .task {
                    DispatchQueue.main.async {
                        let pathReference = Storage.storage().reference(withPath: "/resizedMeals")
                        Firestore.firestore().collection("Meals").addSnapshotListener { querySnapshot, error in
                            if let error = error {
                                print(error.localizedDescription)
                                return
                            }
                            if let documentChanges = querySnapshot?.documentChanges, !documentChanges.isEmpty {
                                var first = false
                                if habitat.mealCells.isEmpty {
                                    first = true
                                }
                                for document in documentChanges {
                                    let doc = document.document
                                    let data = doc.data()
                                    pathReference.child("/\(doc.documentID).png").getData(maxSize: 1 * 2000 * 2000) { imageData, error in
                                        var mealImage: UIImage?
                                        if let imageData = imageData {
                                            mealImage = UIImage(data: imageData)
                                        }
                                        let mealCell = MealCell(docId: doc.documentID, title: data["title"] as! String, subtitle: data["subtitle"] as! String, cals: data["calories"] as! Int, carbs: data["carbohydrate"] as! Int, fat: data["totalFat"] as! Int, protein: data["protein"] as! Int, sku: data["sku"] as! Int, mealType: MealType(rawValue: data["imageTag"] as! String)!, mealImage: mealImage)
                                        if first {
                                            habitat.mealCells.append(mealCell)
                                            if documentChanges.last == document {
                                                habitat.reloadMenuCells()
                                            }
                                        } else if let mealIndex = habitat.mealCells.firstIndex(where: { $0.docId == doc.documentID }) {
                                            habitat.mealCells[mealIndex] = mealCell
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .task {
                    DispatchQueue.main.async {
                        Firestore.firestore().collection("Menus").addSnapshotListener { querySnapshot, error in
                            if let error = error {
                                print(error.localizedDescription)
                                return
                            }
                            if let documentChanges = querySnapshot?.documentChanges, !documentChanges.isEmpty {
                                print(documentChanges)
                                var first = false
                                if habitat.menuCells.isEmpty {
                                    first = true
                                }
                                for document in documentChanges {
                                    let doc = document.document
                                    let data = doc.data()
                                    var menuMeals = [MealCell: Int]()
                                    var mealTypeCount = [MealType: Int]()
                                    let cellDict = data["meals"] as! [String: Int]
                                    for cell in cellDict {
                                        if let mealCell = habitat.mealCells.first(where: { $0.docId == cell.key }) {
                                            menuMeals[mealCell] = cell.value
                                            if let _ = mealTypeCount[mealCell.mealType] {
                                                mealTypeCount[mealCell.mealType]! += 1
                                            } else {
                                                mealTypeCount[mealCell.mealType] = 1
                                            }
                                        }
                                    }
                                    let menuCell = MenuCell(docId: doc.documentID, selectedMenu: data["selectedMenu"] as! Bool, mealCells: menuMeals, mealTypeCount: mealTypeCount)
                                    if !first, let menuIndex = habitat.menuCells.firstIndex(where: { $0.docId == doc.documentID }){
                                        habitat.menuCells[menuIndex] = menuCell
                                    } else {
                                        habitat.menuCells.append(menuCell)
                                    }
                                }
                            }
                            if habitat.menuCells.count > 1 {
                                if let selectedIndex = habitat.menuCells.firstIndex(where: { $0.selectedMenu }) {
                                    habitat.menuCells.insert(habitat.menuCells[selectedIndex], at: 0)
                                    habitat.menuCells.remove(at: selectedIndex+1)
                                }
                            }
                        }
                    }
                }
        }
    }
}

