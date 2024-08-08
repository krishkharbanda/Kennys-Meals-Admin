//
//  ProductionOrderDetailView.swift
//  Kennys Meals Admin
//
//  Created by Krish on 8/8/24.
//

import SwiftUI
import FirebaseFirestore

struct ProductionOrderDetailView: View {
    
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
    @State private var scanErrorText = String()
    @State private var isScanError = false
    @State private var deletingCell: MealCell?
    @State private var isDeleting = false
    
    var body: some View {
        ZStack {
            if mealsViewModel.isShowingDetail {
                MealDetailView(meal: $mealsViewModel.selectedMeal)
                    .environmentObject(mealsViewModel)
                    .preferredColorScheme(.light)
            } else {
                detailBody
            }
        }
        .onAppear {
            tempMenu = menuCell
            mealCells = Array(menuCell.mealCells.keys)
            mealsViewModel.viewingMealFromMenu = true
        }
        .onDisappear {
            if isEditing {
                menuCell = tempMenu
            }
            mealsViewModel.isShowingDetail = false
            mealsViewModel.viewingMealFromMenu = false
            if !mealCells.isEmpty {
                var mealsDict = [String: Int]()
                for mealCell in mealCells {
                    mealsDict[mealCell.docId] = menuCell.mealCells[mealCell]
                }
                var tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                Firestore.firestore().collection("Production Orders").document(tomorrow.convertToDocID).setData(["meals": mealsDict, "menu": menuCell.docId])
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
        .alert("Change \(selectedMeal?.docId ?? "")", isPresented: $isEditingCount) {
            TextField("count", text: $countText)
            Button("Ok", action: changeCount)
        } message: {
            Text("Edit the count of \(selectedMeal?.docId ?? "").")
        }
    }
    
    var detailBody: some View {
        VStack {
            VStack {
                HStack {
                    Button {
                        mealsViewModel.isShowingDetail = false
                        mealsViewModel.viewingMealFromMenu = false
                        if !mealCells.isEmpty {
                            var mealsDict = [String: Int]()
                            for mealCell in mealCells {
                                mealsDict[mealCell.docId] = menuCell.mealCells[mealCell]
                            }
                            var tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                            Firestore.firestore().collection("Production Orders").document(tomorrow.convertToDocID).setData(["meals": mealsDict, "menu": menuCell.docId])
                        }
                        viewModel.isShowingDetail = false
                    } label: {
                        Image(systemName: "xmark")
                    }
                    Spacer()
                    if viewModel.canWrite {
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
                    Button {
                        
                    } label: {
                        Image(systemName: "tray.full")
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
