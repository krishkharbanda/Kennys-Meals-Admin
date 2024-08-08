//
//  MenuView.swift
//  Kennys Meals Admin
//
//  Created by Krish on 7/25/24.
//

import SwiftUI
import FirebaseFirestore

struct MenuView: View {
    
    @EnvironmentObject var habitat: Habitat
    @Binding var presentSideMenu: Bool
    @StateObject private var viewModel = MenuViewModel()
    @StateObject private var mealsViewModel = MealsViewModel()
    @State private var isShowingDetail = false
    @State private var isDeleting = false
    @State private var deletingCell: MenuCell?
    @State private var isDeletingError = false
    @State private var isShowingMealsDetail = false
    @State private var isAddingMeals = false
    @State private var isShowingProductionOrderDetail = false
    
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
                }
                .padding()
                Text("Total Menus: \(viewModel.menuCells.count)")
                ScrollView {
                    ForEach(0..<viewModel.menuCells.count, id: \.self) { i in
                        Button {
                            guard let selectedCell = habitat.menuCells.first(where: { $0.docId == viewModel.menuCells[i].docId }) else { return }
                            viewModel.selectedMenuCell = selectedCell
                            viewModel.isShowingDetail = true
                        } label: {
                            MenuCellView(menuCell: $viewModel.menuCells[i])
                                .environmentObject(viewModel)
                                .padding(.top, 3)
                                .contextMenu {
                                    Group {
                                        if !viewModel.menuCells[i].selectedMenu {
                                            Button {
                                                guard let selectedIndex = habitat.menuCells.firstIndex(where: { $0.selectedMenu }) else { return }
                                                Firestore.firestore().collection("Menus").document(habitat.menuCells[selectedIndex].docId).setData(["selectedMenu": false], merge: true)
                                                habitat.menuCells[selectedIndex].selectedMenu = false
                                                Firestore.firestore().collection("Menus").document(viewModel.menuCells[i].docId).setData(["selectedMenu": true], merge: true)
                                                guard let newIndex = habitat.menuCells.firstIndex(where: { $0.docId == viewModel.menuCells[i].docId }) else { return }
                                                habitat.menuCells[newIndex].selectedMenu = true
                                            } label: {
                                                HStack {
                                                    Image(systemName: "checkmark.circle")
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fit)
                                                    Text("Select Menu")
                                                }
                                            }
                                        }
                                        Button {
                                            deletingCell = habitat.menuCells.first(where: { $0.docId == viewModel.menuCells[i].docId })
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
                                }
                        }
                        
                    }
                }
            }
            .alert("Deleting \(deletingCell?.docId ?? "")?", isPresented: $isDeleting, actions: {
                Button("Cancel", role: .cancel) { isDeleting = false }
                Button("Delete", role: .destructive) {
                    let success = habitat.delete(menuCell: deletingCell!)
                    if !success {
                        isDeletingError = true
                    }
                }
            }, message: {
                Text("Deleting will permantely remove the menu.")
            })
            .alert("Error Deleting \(deletingCell?.docId ?? "")", isPresented: $isDeletingError, actions: {
                Button("Ok") { isDeletingError = false }
            }, message: {
                Text("An error occured. Try again later.")
            })
            .onTapGesture {
                self.hideKeyboard()
            }
            .onChange(of: habitat.menuCells, { oldValue, newValue in
                viewModel.menuCells = newValue
                viewModel.unsearchedMenuCells = newValue
            })
            .onChange(of: habitat.mealCells, { oldValue, newValue in
                mealsViewModel.mealCells = newValue
                mealsViewModel.unsearchedMealCells = newValue
                mealsViewModel.filter(allMeals: newValue)
                mealsViewModel.sort()
                mealsViewModel.search()
            })
            .onAppear {
                viewModel.canWrite = habitat.user.canWrite
                viewModel.menuCells = habitat.menuCells
                viewModel.unsearchedMenuCells = viewModel.menuCells
                mealsViewModel.canWrite = habitat.user.canWrite
                mealsViewModel.mealCells = habitat.mealCells
                mealsViewModel.unsearchedMealCells = habitat.mealCells
                mealsViewModel.sort()
                if let selectedMenu = habitat.menuCells.first(where: { $0.selectedMenu }) {
                    viewModel.selectedMenu = selectedMenu
                }
            }
            .onChange(of: viewModel.isShowingDetail, { oldValue, newValue in
                isShowingDetail = newValue
            })
            .onChange(of: viewModel.isShowingProductionOrderDetail, { oldValue, newValue in
                isShowingProductionOrderDetail = newValue
            })
            .onChange(of: viewModel.searchText, { oldValue, newValue in
                if oldValue != newValue {
                    viewModel.search()
                }
            })
            .popover(isPresented: $isShowingDetail, content: {
                MenuDetailView(menuCell: $viewModel.selectedMenuCell)
                    .environmentObject(viewModel)
                    .environmentObject(mealsViewModel)
                    .environmentObject(habitat)
                    .preferredColorScheme(.light)
            })
            .popover(isPresented: $isShowingProductionOrderDetail, content: {
                
            })
            .navigationTitle("Menus")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                HStack {
                    Spacer()
                    Button {
                        viewModel.isShowingProductionOrder = true
                    } label: {
                        Image(systemName: "eject")
                    }
                    Button {
                        var count = 1
                        var notFound = false
                        while !notFound {
                            if let _ = habitat.menuCells.firstIndex(where: { $0.docId == "New Menu\(count == 1 ? "":" \(count)")" }) {
                                count += 1
                            } else {
                                notFound = true
                            }
                        }
                        let newMenu = MenuCell(docId: "New Menu\(count == 1 ? "":" \(count)")", selectedMenu: false, mealCells: [:], mealTypeCount: [:])
                        viewModel.selectedMenuCell = newMenu
                        viewModel.isShowingDetail = true
                    } label: {
                        Image(systemName: "plus.rectangle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 24)
                            .foregroundStyle(.black)
                    }
                    Button {
                        presentSideMenu.toggle()
                    } label: {
                        if presentSideMenu {
                            Image(systemName: "xmark")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 24)
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
}
