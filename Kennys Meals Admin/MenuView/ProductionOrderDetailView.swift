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
    @State private var tomorrowString = String()
    @State private var expirationString = String()
    
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
            mealCells = Array(viewModel.productionOrder.keys)
            mealsViewModel.viewingMealFromMenu = true
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            var formatter = DateFormatter()
            formatter.dateFormat = "MM/dd/yyyy"
            tomorrowString = formatter.string(from: tomorrow)
            let expiration = Calendar.current.date(byAdding: .day, value: 8, to: tomorrow)!
            expirationString = formatter.string(from: expiration)
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
                let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                Firestore.firestore().collection("Production Orders").document(tomorrow.convertToDocID).setData(["meals": mealsDict, "menu": menuCell.docId])
            }
            viewModel.isShowingProductionOrderDetail = false
        }
        .onChange(of: menuCell.mealCells) { oldValue, newValue in
            mealCells = Array(viewModel.productionOrder.keys)
        }
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
                            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                            Firestore.firestore().collection("Production Orders").document(tomorrow.convertToDocID).setData(["meals": mealsDict, "menu": menuCell.docId])
                        }
                        viewModel.isShowingProductionOrderDetail = false
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
                                        mealsDict[mealCell.docId] = viewModel.productionOrder[mealCell]
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
                Text("Production Order")
                    .font(.title)
                    .bold()
                    .multilineTextAlignment(.center)
                Text("\(menuCell.docId) - \(tomorrowString)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                Text("Expires \(expirationString)")
                    .font(.title3)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)

            }
            .padding()
            ScrollView {
                ForEach(0..<mealCells.count, id: \.self) { i in
                    if isEditing || viewModel.productionOrder[mealCells[i]] ?? 0 != 0 {
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
                            HStack {
                                Spacer()
                                Button {
                                    viewModel.productionOrder[mealCells[i]]! = 0
                                } label: {
                                    Text("None")
                                        .font(.title3)
                                        .foregroundStyle((!isEditing || viewModel.productionOrder[mealCells[i]] ?? 0 == 0) ? Color.gray.opacity(0.6):Color.orange)
                                        .padding()
                                }
                                .disabled(!isEditing || viewModel.productionOrder[mealCells[i]] ?? 0 == 0)
                                Button {
                                    if viewModel.productionOrder[mealCells[i]]! < 10 {
                                        viewModel.productionOrder[mealCells[i]]! = 0
                                    } else {
                                        viewModel.productionOrder[mealCells[i]]! -= 10
                                    }
                                } label: {
                                    Text("-")
                                        .foregroundStyle(.white)
                                        .padding()
                                        .background(((!isEditing || viewModel.productionOrder[mealCells[i]] ?? 0 <= 0) ? Color.gray:Color.orange).opacity(0.6))
                                        .clipShape(RoundedRectangle(cornerSize: CGSize(width: 10, height: 10), style: .circular))
                                }
                                .disabled(!isEditing || viewModel.productionOrder[mealCells[i]] ?? 0 <= 0)
                                Button {
                                    countText = "\(String(describing: viewModel.productionOrder[mealCells[i]] ?? 0))"
                                    selectedMeal = mealCells[i]
                                    isEditingCount = true
                                } label: {
                                    Text("\(String(describing: viewModel.productionOrder[mealCells[i]] ?? 0))")
                                        .font(.title3)
                                }
                                .disabled(!isEditing)
                                Button {
                                    viewModel.productionOrder[mealCells[i]]! += 10
                                } label: {
                                    Text("+")
                                        .foregroundStyle(.white)
                                        .padding()
                                        .background((!isEditing ? Color.gray:Color.orange).opacity(0.6))
                                        .clipShape(RoundedRectangle(cornerSize: CGSize(width: 10, height: 10), style: .circular))
                                }
                                .disabled(!isEditing)
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top, 3)
                    }
                }
            }
            Spacer()
        }
    }
    
    private func changeCount() {
        guard let count = Int(countText) else { return }
        if count != viewModel.productionOrder[selectedMeal!] {
            viewModel.productionOrder[selectedMeal!] = count
        }
        isEditingCount = false
    }
}
