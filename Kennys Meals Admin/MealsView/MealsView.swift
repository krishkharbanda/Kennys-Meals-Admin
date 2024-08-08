//
//  MealsView.swift
//  Kennys Meals Admin
//
//  Created by Krish on 6/16/24.
//

import SwiftUI
import FirebaseFirestore

struct MealsView: View {
    
    @EnvironmentObject var habitat: Habitat
    @Binding var presentSideMenu: Bool
    @StateObject private var viewModel = MealsViewModel()
    @StateObject private var scanViewModel = ScanViewModel()
    @State private var isShowingDetail = false
    @State private var isShowingScanner = false
    @State private var isScanError = false
    @State private var scanErrorText = String()
    @State private var selectedSku = Int()
    @State private var mealsCountText = String()
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(.gray.opacity(0.5))
                        .frame(maxHeight: 24)
                        .padding(.trailing, 5)
                    TextField("search meals...", text: $viewModel.searchText)
                        .font(.callout)
                        .textInputAutocapitalization(.never)
                        .tint(.orange)
                        .submitLabel(.search)
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerSize: CGSize(width: 10, height: 5)))
                        .shadow(radius: 2.5)
                        .onSubmit {
                            self.hideKeyboard()
                        }
                    Button {
                        viewModel.isShowingScanner = scanViewModel.dataScannerAccessStatus == .scannerAvailable
                        switch scanViewModel.dataScannerAccessStatus {
                        case .scannerAvailable:
                            scanErrorText = ""
                        case .cameraNotAvailable:
                            scanErrorText = "Your device does not have a camera."
                        case .scannerNotAvailable:
                            scanErrorText = "Your device does not have barcode scanner support."
                        case .cameraAccessNotGranted:
                            scanErrorText = "Please provide access to the camera in settings."
                        case .notDetermined:
                            scanErrorText = ""
                        }
                        isScanError = !(viewModel.isShowingScanner || scanViewModel.dataScannerAccessStatus == .notDetermined)
                    } label: {
                        Image(systemName: "barcode.viewfinder")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundStyle(.gray.opacity(0.5))
                            .frame(maxHeight: 24)
                            .padding(.trailing, 5)
                    }
                    .onChange(of: selectedSku, { oldValue, newValue in
                        if newValue != 0 {
                            selectSku()
                        }
                    })
                }
                .padding()
                Text("\(mealsCountText): \(viewModel.mealCells.count)")
                ScrollView {
                    ForEach(0..<viewModel.mealCells.count, id: \.self) { i in
                        Button {
                            viewModel.getSelectedMeal(mealCell: viewModel.mealCells[i])
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerSize: CGSize(width: 20, height: 10))
                                    .foregroundStyle(.white)
                                    .shadow(radius: 5)
                                MealCellView(mealCell: $viewModel.mealCells[i])
                            }
                            .padding(.top, 3)
                        }
                    }
                }
            }
            .alert("Scanner Error", isPresented: $isScanError, actions: {
                Button{isScanError = false} label: { Text("Ok") }
                
            }, message: {
                Text(scanErrorText)
            })
            .onChange(of: habitat.mealCells, { oldValue, newValue in
                viewModel.mealCells = newValue
                viewModel.filterByMenu(allMeals: newValue, allMenus: habitat.menuCells)
                viewModel.sort()
                viewModel.search()
            })
            .onTapGesture {
                self.hideKeyboard()
            }
            .task {
                await scanViewModel.requestDataScannerAccessStatus()
            }
            .onAppear {
                viewModel.selectedMealType = .all
                viewModel.selectedMenuIndex = 0
                viewModel.selectedSort = .alphabet
                viewModel.selectedOrder = .ascending
                viewModel.menuDocIds.append(contentsOf: habitat.menuCells.map({ $0.docId }))
                viewModel.canWrite = habitat.user.canWrite
                viewModel.mealCells = habitat.mealCells
                viewModel.unsearchedMealCells = viewModel.mealCells
                viewModel.sort()
                mealsCountText = "Total Meals"
            }
            .onChange(of: scanViewModel.isShowingScanner, { oldValue, newValue in
                viewModel.isShowingScanner = newValue
            })
            .onChange(of: viewModel.isShowingScanner, { oldValue, newValue in
                isShowingScanner = newValue
            })
            .onChange(of: viewModel.isShowingDetail, { oldValue, newValue in
                print(newValue)
                isShowingDetail = newValue
            })
            .onChange(of: viewModel.searchText, { oldValue, newValue in
                if oldValue != newValue {
                    viewModel.search()
                }
            })
            .onChange(of: viewModel.selectedMealType, { oldValue, newValue in
                if oldValue.rawValue != newValue.rawValue {
                    viewModel.filterByMenu(allMeals: habitat.mealCells, allMenus: habitat.menuCells)
                    viewModel.sort()
                    mealsCountText = "\(viewModel.selectedMenuIndex == 0 ? "":"\(viewModel.menuDocIds[viewModel.selectedMenuIndex])'s ")Total\(newValue == .all ? "":" \(newValue.rawValue)") Meals"
                }
            })
            .onChange(of: viewModel.selectedMenuIndex, { oldValue, newValue in
                viewModel.filterByMenu(allMeals: habitat.mealCells, allMenus: habitat.menuCells)
                viewModel.sort()
                mealsCountText = "\(newValue == 0 ? "":"\(viewModel.menuDocIds[newValue])'s ")Total\(viewModel.selectedMealType == .all ? "":" \(viewModel.selectedMealType.rawValue)") Meals"
            })
            .onChange(of: viewModel.selectedSort, { oldValue, newValue in
                if oldValue.rawValue != newValue.rawValue {
                    viewModel.sort()
                }
            })
            .onChange(of: viewModel.selectedOrder, { oldValue, newValue in
                if oldValue.rawValue != newValue.rawValue {
                    viewModel.mealCells.reverse()
                }
            })
            .onChange(of: viewModel.editedMeal, { oldValue, newValue in
                if newValue {
                    if let index = habitat.mealCells.firstIndex(where: {$0.docId == viewModel.selectedMeal.docId}) {
                        habitat.mealCells[index] = MealCell(docId: viewModel.selectedMeal.docId, title: viewModel.selectedMeal.title, subtitle: viewModel.selectedMeal.subtitle, cals: viewModel.selectedMeal.nutritionFacts.calories, carbs: viewModel.selectedMeal.nutritionFacts.totalCarb, fat: viewModel.selectedMeal.nutritionFacts.totalFat, protein: viewModel.selectedMeal.nutritionFacts.protein, sku: viewModel.selectedMeal.sku, mealType: viewModel.selectedMeal.mealType, mealImage: viewModel.selectedMeal.image)
                    } else {
                        habitat.mealCells.append(MealCell(docId: viewModel.selectedMeal.docId, title: viewModel.selectedMeal.title, subtitle: viewModel.selectedMeal.subtitle, cals: viewModel.selectedMeal.nutritionFacts.calories, carbs: viewModel.selectedMeal.nutritionFacts.totalCarb, fat: viewModel.selectedMeal.nutritionFacts.totalFat, protein: viewModel.selectedMeal.nutritionFacts.protein, sku: viewModel.selectedMeal.sku, mealType: viewModel.selectedMeal.mealType, mealImage: viewModel.selectedMeal.image))
                    }
                    viewModel.editedMeal = false
                }
            })
            .popover(isPresented: $isShowingScanner, content: {
                ScanView(selectedSku: $selectedSku)
                    .environmentObject(scanViewModel)
                    .preferredColorScheme(.light)
            })
            .popover(isPresented: $isShowingDetail, content: {
                MealDetailView(meal: $viewModel.selectedMeal)
                    .environmentObject(viewModel)
                    .preferredColorScheme(.light)
            })
            .navigationTitle("Meals")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                HStack {
                    Spacer()
                    Menu {
                        Menu {
                            Picker("Meal Type", selection: $viewModel.selectedMealType) {
                                ForEach(MealType.allCases) { mealType in
                                    Text(mealType.rawValue)
                                }
                            }
                        } label: {
                            Text("Meal Type")
                        }
                        Menu {
                            Picker("Menu", selection: $viewModel.selectedMenuIndex) {
                                ForEach(0..<viewModel.menuDocIds.count, id: \.self) { i in
                                    Text(viewModel.menuDocIds[i])
                                }
                            }
                        } label: {
                            Text("Menu")
                        }
                        Menu {
                            Picker("Sort", selection: $viewModel.selectedSort) {
                                ForEach(SortOptions.allCases) { sort in
                                    Text(sort.rawValue)
                                }
                            }
                        } label: {
                            Text("Sort")
                        }
                        Menu {
                            Picker("Order", selection: $viewModel.selectedOrder) {
                                ForEach(OrderOptions.allCases) { order in
                                    Text(order.rawValue)
                                }
                            }
                        } label: {
                            Text("Order")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .foregroundStyle(.black)
                    }
                    Button {
                        presentSideMenu.toggle()
                    } label: {
                        if presentSideMenu {
                            Image(systemName: "xmark")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundStyle(.black)
                        } else {
                            Image("menu")
                                .resizable()
                                .frame(width: 32, height: 32)
                        }
                    }
                }
            }
        }
    }
    
    func selectSku() {
        if let mealCell = habitat.mealCells.first(where: { $0.sku == selectedSku }) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            selectedSku = 0
            viewModel.getSelectedMeal(mealCell: mealCell)
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            scanErrorText = "Barcode not found in database."
            scanViewModel.isShowingScanner = false
            scanViewModel.isShowingScanner = true
            isScanError = true
        }
    }
}
enum SortOptions: String, CaseIterable, Identifiable, Equatable {
    var id: Self {
        return self
    }
    
    case alphabet = "A-Z"
    case cals = "Calories"
    case carbs = "Carbohydrates"
    case fat = "Fat"
    case protein = "Protein"
}
enum OrderOptions: String, CaseIterable, Identifiable, Equatable {
    var id: Self {
        return self
    }
    
    case ascending = "Ascending"
    case descending = "Descending"
}
