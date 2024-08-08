//
//  MenuDetailView.swift
//  Kennys Meals Admin
//
//  Created by Krish on 8/2/24.
//

import SwiftUI
import FirebaseFirestore

struct MenuDetailView: View {
    
    @Binding var menuCell: MenuCell
    @EnvironmentObject var viewModel: MenuViewModel
    @EnvironmentObject var mealsViewModel: MealsViewModel
    @EnvironmentObject var habitat: Habitat
    @State private var tempMenu = MenuCell()
    @State private var isEditing = false
    @State private var mealCells = [MealCell]()
    @State private var isEditingCount = false
    @State private var selectedMeal: MealCell?
    @State private var countText = String()
    @StateObject private var scanViewModel = ScanViewModel()
    @State private var scanErrorText = String()
    @State private var isScanError = false
    @State private var deletingCell: MealCell?
    @State private var isDeleting = false
    
    var body: some View {
        ZStack {
            if mealsViewModel.isShowingScanner {
                ScanView(selectedSku: $mealsViewModel.selectedSku)
                    .environmentObject(scanViewModel)
                    .preferredColorScheme(.light)
            } else if mealsViewModel.isShowingDetail {
                MealDetailView(meal: $mealsViewModel.selectedMeal)
                    .environmentObject(mealsViewModel)
                    .preferredColorScheme(.light)
            } else if viewModel.isAddingMeals {
                AddMealsView()
                    .environmentObject(viewModel)
                    .environmentObject(mealsViewModel)
                    .environmentObject(habitat)
                    .preferredColorScheme(.light)
            } else {
                detailBody
            }
        }
        .onAppear {
            tempMenu = menuCell
            mealCells = Array(menuCell.mealCells.keys)
            mealsViewModel.viewingMealFromMenu = true
            scanViewModel.isMenuSelecting = true
        }
        .onDisappear {
            if isEditing {
                menuCell = tempMenu
            }
            mealsViewModel.isShowingScanner = false
            mealsViewModel.isShowingDetail = false
            mealsViewModel.viewingMealFromMenu = false
            viewModel.isAddingMeals = false
            if !mealCells.isEmpty {
                var mealsDict = [String: Int]()
                for mealCell in mealCells {
                    mealsDict[mealCell.docId] = menuCell.mealCells[mealCell]
                }
                Firestore.firestore().collection("Menus").document(menuCell.docId).setData(["meals": mealsDict, "selectedMenu": menuCell.selectedMenu], merge: false)
            }
            viewModel.isShowingDetail = false
        }
        .onChange(of: menuCell.mealCells) { oldValue, newValue in
            mealCells = Array(menuCell.mealCells.keys)
        }
        .onChange(of: mealsViewModel.selectedSku, { oldValue, newValue in
            if newValue != 0 {
                selectSku()
            }
        })
        .onChange(of: mealsViewModel.isScanError, { oldValue, newValue in
            scanErrorText = mealsViewModel.scanErrorText
            isScanError = newValue
        })
        .onChange(of: scanViewModel.isShowingScanner, { oldValue, newValue in
            mealsViewModel.isShowingScanner = newValue
        })
        .onChange(of: viewModel.isAddingMeals, { oldValue, newValue in
            if !newValue {
                menuCell.mealCells = viewModel.selectedMenu.mealCells
            }
        })
        .alert("Change \(selectedMeal?.docId ?? "")", isPresented: $isEditingCount) {
            TextField("count", text: $countText)
            Button("Ok", action: changeCount)
        } message: {
            Text("Edit the count of \(selectedMeal?.docId ?? "").")
        }
        .alert("Scanner Error", isPresented: $isScanError, actions: {
            Button{isScanError = false} label: { Text("Ok") }
        }, message: {
            Text(scanErrorText)
        })
        .alert("Deleting \(deletingCell?.docId ?? "")?", isPresented: $isDeleting, actions: {
            Button("Cancel", role: .cancel) { isDeleting = false }
            Button("Delete", role: .destructive) {
                menuCell.mealCells.removeValue(forKey: deletingCell!)
            }
        }, message: {
            Text("Deleting will permantely remove the menu.")
        })
    }
    
    var detailBody: some View {
        VStack {
            VStack {
                HStack {
                    Button {
                        mealsViewModel.isShowingScanner = false
                        mealsViewModel.isShowingDetail = false
                        mealsViewModel.viewingMealFromMenu = false
                        viewModel.isAddingMeals = false
                        if !mealCells.isEmpty {
                            var mealsDict = [String: Int]()
                            for mealCell in mealCells {
                                mealsDict[mealCell.docId] = menuCell.mealCells[mealCell]
                            }
                            Firestore.firestore().collection("Menus").document(menuCell.docId).setData(["meals": mealsDict, "selectedMenu": menuCell.selectedMenu], merge: false)
                        }
                        viewModel.isShowingDetail = false
                    } label: {
                        Image(systemName: "xmark")
                    }
                    Spacer()
                    if viewModel.canWrite {
                        Button {
                            viewModel.isAddingMeals = true
                        } label: {
                            Text("Add")
                        }
                        .padding(.trailing, 3.5)
                        Button {
                            if !isEditing {
                                tempMenu = menuCell
                            } else {
                                if !mealCells.isEmpty {
                                    var mealsDict = [String: Int]()
                                    for mealCell in mealCells {
                                        mealsDict[mealCell.docId] = menuCell.mealCells[mealCell]
                                    }
                                    Firestore.firestore().collection("Menus").document(menuCell.docId).setData(["meals": mealsDict, "selectedMenu": menuCell.selectedMenu], merge: false)
                                }
                            }
                            isEditing.toggle()
                        } label: {
                            Text(isEditing ? "Done":"Edit")
                        }
                        if isEditing {
                            Button {
                                menuCell = tempMenu
                                isEditing.toggle()
                            } label: {
                                Text("Cancel")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }
                .padding(.vertical)
                TextField("title", text: $menuCell.docId, axis: .vertical)
                    .font(.title)
                    .bold()
                    .multilineTextAlignment(.center)
                    .disabled(!isEditing)
                    .lineLimit(3)
            }
            .padding()
            ScrollView {
                ForEach(0..<mealCells.count, id: \.self) { i in
                    VStack {
                        Button {
                            mealsViewModel.getSelectedMeal(mealCell: mealCells[i])
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerSize: CGSize(width: 20, height: 10))
                                    .foregroundStyle(.white)
                                    .shadow(radius: 5)
                                MealCellView(mealCell: $mealCells[i])
                            }
                            .padding(.top, 3)
                        }
                        .contextMenu {
                            Button {
                                deletingCell = mealCells[i]
                                isDeleting = true
                            } label: {
                                HStack {
                                    Image(systemName: "trash")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                    Text("Delete")
                                }
                            }
                        }
                        HStack {
                            Spacer()
                            Button {
                                menuCell.mealCells[mealCells[i]]! -= 10
                            } label: {
                                Text("-")
                                    .foregroundStyle(.white)
                                    .padding()
                                    .background(.gray.opacity(0.6))
                                    .clipShape(RoundedRectangle(cornerSize: CGSize(width: 10, height: 10), style: .circular))
                            }
                            .disabled(!isEditing || menuCell.mealCells[mealCells[i]] ?? 0 <= 10)
                            Button {
                                countText = "\(String(describing: menuCell.mealCells[mealCells[i]] ?? 0))"
                                selectedMeal = mealCells[i]
                                isEditingCount = true
                            } label: {
                                Text("\(String(describing: menuCell.mealCells[mealCells[i]] ?? 0))")
                                    .font(.title3)
                            }
                            .disabled(!isEditing)
                            Button {
                                menuCell.mealCells[mealCells[i]]! += 10
                            } label: {
                                Text("+")
                                    .foregroundStyle(.white)
                                    .padding()
                                    .background(.gray.opacity(0.6))
                                    .clipShape(RoundedRectangle(cornerSize: CGSize(width: 10, height: 10), style: .circular))
                            }
                            .disabled(!isEditing)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 3)
                }
            }
            Spacer()
        }
    }
    
    private func changeCount() {
        guard let count = Int(countText) else { return }
        if count != menuCell.mealCells[selectedMeal!] {
            menuCell.mealCells[selectedMeal!] = count
        }
        isEditingCount = false
    }
    
    func selectSku() {
        if let mealCell = mealsViewModel.mealCells.first(where: { $0.sku == mealsViewModel.selectedSku }) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            mealsViewModel.selectedSku = 0
            mealsViewModel.searchText = mealCell.docId
            mealsViewModel.search()
            mealsViewModel.isShowingScanner = false
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            scanErrorText = "Barcode not found in database."
            mealsViewModel.isShowingScanner = false
            mealsViewModel.isShowingScanner = true
            isScanError = true
        }
    }
}
struct AddMealsView: View {
    
    @EnvironmentObject var menuViewModel: MenuViewModel
    @EnvironmentObject var mealsViewModel: MealsViewModel
    @EnvironmentObject var habitat: Habitat
    @StateObject private var scanViewModel = ScanViewModel()
    @State private var isShowingDetail = false
    @State private var isShowingScanner = false
    @State private var selectedSku = Int()
    @State private var countText = String()
    @State private var selectedMeal: MealCell?
    @State private var isEditingCount = false
    @State private var tempMealCells = [MealCell: Int]()
    @State private var mealsCountText = String()
    
    var body: some View {
        VStack {
            VStack {
                HStack {
                    Button {
                        menuViewModel.isAddingMeals = false
                    } label: {
                        Text("Done")
                    }
                    Button {
                        menuViewModel.selectedMenu.mealCells = tempMealCells
                        menuViewModel.isAddingMeals = false
                    } label: {
                        Text("Cancel")
                            .foregroundStyle(.red)
                    }
                    Spacer()
                    Menu {
                        Menu {
                            Picker("Meal Type", selection: $mealsViewModel.selectedMealType) {
                                ForEach(MealType.allCases) { mealType in
                                    Text(mealType.rawValue)
                                }
                            }
                        } label: {
                            Text("Meal Type")
                        }
                        Menu {
                            Picker("Menu", selection: $mealsViewModel.selectedMenuIndex) {
                                ForEach(0..<mealsViewModel.menuDocIds.count, id: \.self) { i in
                                    Text(mealsViewModel.menuDocIds[i])
                                }
                            }
                        } label: {
                            Text("Menu")
                        }
                        Menu {
                            Picker("Sort", selection: $mealsViewModel.selectedSort) {
                                ForEach(SortOptions.allCases) { sort in
                                    Text(sort.rawValue)
                                }
                            }
                        } label: {
                            Text("Sort")
                        }
                        Menu {
                            Picker("Order", selection: $mealsViewModel.selectedOrder) {
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
                }
                .padding(.vertical)
                HStack {
                    Text("Add Meals")
                        .font(.title)
                        .bold()
                    Spacer()
                }
                HStack {
                    Image(systemName: "magnifyingglass")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(.gray.opacity(0.5))
                        .frame(maxHeight: 24)
                        .padding(.trailing, 5)
                    TextField("search meals...", text: $mealsViewModel.searchText)
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
                        mealsViewModel.isShowingScanner = scanViewModel.dataScannerAccessStatus == .scannerAvailable
                        switch scanViewModel.dataScannerAccessStatus {
                        case .scannerAvailable:
                            mealsViewModel.scanErrorText = ""
                        case .cameraNotAvailable:
                            mealsViewModel.scanErrorText = "Your device does not have a camera."
                        case .scannerNotAvailable:
                            mealsViewModel.scanErrorText = "Your device does not have barcode scanner support."
                        case .cameraAccessNotGranted:
                            mealsViewModel.scanErrorText = "Please provide access to the camera in settings."
                        case .notDetermined:
                            mealsViewModel.scanErrorText = ""
                        }
                        mealsViewModel.isScanError = !(mealsViewModel.isShowingScanner || scanViewModel.dataScannerAccessStatus == .notDetermined)
                    } label: {
                        Image(systemName: "barcode.viewfinder")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundStyle(.gray.opacity(0.5))
                            .frame(maxHeight: 24)
                            .padding(.trailing, 5)
                    }
                }
                
            }
            .padding(.horizontal)
            Text("\(mealsCountText): \(mealsViewModel.mealCells.count)")
            ScrollView {
                ForEach(0..<mealsViewModel.mealCells.count, id: \.self) { i in
                    HStack {
                        Button {
                            if mealsViewModel.selectedMealCells.contains(where: { $0.docId == mealsViewModel.mealCells[i].docId }) {
                                menuViewModel.selectedMenu.mealCells.removeValue(forKey: mealsViewModel.mealCells[i])
                            } else {
                                menuViewModel.selectedMenu.mealCells[mealsViewModel.mealCells[i]] = 10
                            }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerSize: CGSize(width: 20, height: 10))
                                    .foregroundStyle(mealsViewModel.selectedMealCells.contains(where: { $0.docId == mealsViewModel.mealCells[i].docId}) ? .orange:.white)
                                    .shadow(radius: 5)
                                MealCellView(mealCell: $mealsViewModel.mealCells[i])
                            }
                            .padding(.top, 3)
                        }
                        if mealsViewModel.selectedMealCells.contains(where: { $0.docId == mealsViewModel.mealCells[i].docId}) {
                            HStack {
                                Button("-") {
                                    menuViewModel.selectedMenu.mealCells[mealsViewModel.mealCells[i]]! -= 10
                                }
                                Button("\(String(describing: menuViewModel.selectedMenu.mealCells[mealsViewModel.mealCells[i]] ?? 0))") {
                                    countText = "\(String(describing: menuViewModel.selectedMenu.mealCells[mealsViewModel.mealCells[i]]!))"
                                    selectedMeal = mealsViewModel.mealCells[i]
                                    isEditingCount = true
                                }
                                Button("+") {
                                    menuViewModel.selectedMenu.mealCells[mealsViewModel.mealCells[i]]! += 10
                                }
                            }
                            .padding(5)
                        }
                    }
                }
            }
            Spacer()
        }
        .alert("Change \(selectedMeal?.docId ?? "")", isPresented: $isEditingCount) {
            TextField("count", text: $countText)
            Button("Ok", action: changeCount)
        } message: {
            Text("Edit the count of \(selectedMeal?.docId ?? "").")
        }
        .onTapGesture {
            self.hideKeyboard()
        }
        .task {
            await scanViewModel.requestDataScannerAccessStatus()
        }
        .onAppear {
            mealsViewModel.selectedMealType = .all
            mealsViewModel.selectedMenuIndex = 0
            mealsViewModel.selectedSort = .alphabet
            mealsViewModel.selectedOrder = .ascending
            mealsViewModel.menuDocIds.append(contentsOf: habitat.menuCells.map({ $0.docId }))
            tempMealCells = menuViewModel.selectedMenu.mealCells
            mealsViewModel.selectedMealCells = Array(menuViewModel.selectedMenu.mealCells.keys)
            mealsViewModel.mealCells = habitat.mealCells
            mealsViewModel.unsearchedMealCells = habitat.mealCells
            mealsViewModel.sort()
            mealsCountText = "Total Meals"
        }
        .onChange(of: habitat.mealCells, { oldValue, newValue in
            mealsViewModel.mealCells = newValue
            mealsViewModel.filterByMenu(allMeals: newValue, allMenus: habitat.menuCells)
            mealsViewModel.sort()
            mealsViewModel.search()
        })
        .onChange(of: habitat.menuCells, { oldValue, newValue in
            mealsViewModel.menuDocIds = ["None"]
            let keys = Set(newValue.map({ $0.docId }))
            mealsViewModel.menuDocIds.append(contentsOf: Array(keys))
        })
        .onChange(of: menuViewModel.selectedMenu.mealCells, { oldValue, newValue in
            mealsViewModel.selectedMealCells = Array(newValue.keys)
        })
        .onChange(of: mealsViewModel.isShowingScanner, { oldValue, newValue in
            isShowingScanner = newValue
        })
        .onChange(of: mealsViewModel.isShowingDetail, { oldValue, newValue in
            isShowingDetail = newValue
        })
        .onChange(of: mealsViewModel.searchText, { oldValue, newValue in
            if oldValue != newValue {
                mealsViewModel.search()
            }
        })
        .onChange(of: mealsViewModel.selectedMealType, { oldValue, newValue in
            if oldValue.rawValue != newValue.rawValue {
                mealsViewModel.filterByMenu(allMeals: habitat.mealCells, allMenus: habitat.menuCells)
                mealsViewModel.sort()
                mealsCountText = "\(mealsViewModel.selectedMenuIndex == 0 ? "":"\(mealsViewModel.menuDocIds[mealsViewModel.selectedMenuIndex])'s ")Total\(mealsViewModel.selectedMealType == .all ? "":" \(mealsViewModel.selectedMealType.rawValue)") Meals"
            }
        })
        .onChange(of: mealsViewModel.selectedMenuIndex, { oldValue, newValue in
            mealsViewModel.filterByMenu(allMeals: habitat.mealCells, allMenus: habitat.menuCells)
            mealsViewModel.sort()
            mealsCountText = "\(newValue == 0 ? "":"\(mealsViewModel.menuDocIds[newValue])'s ")Total\(mealsViewModel.selectedMealType == .all ? "":" \(mealsViewModel.selectedMealType.rawValue)") Meals"
        })
        .onChange(of: mealsViewModel.selectedSort, { oldValue, newValue in
            if oldValue.rawValue != newValue.rawValue {
                mealsViewModel.sort()
            }
        })
        .onChange(of: mealsViewModel.selectedOrder, { oldValue, newValue in
            if oldValue.rawValue != newValue.rawValue {
                mealsViewModel.mealCells.reverse()
            }
        })
    }
    private func changeCount() {
        guard let count = Int(countText) else { return }
        if count != menuViewModel.selectedMenu.mealCells[selectedMeal!] {
            menuViewModel.selectedMenu.mealCells[selectedMeal!] = count
        }
        isEditingCount = false
    }
}
