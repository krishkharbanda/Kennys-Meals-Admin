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
            if viewModel.isShowingIngredientsView {
                IngredientsView()
                    .environmentObject(viewModel)
                    .environmentObject(mealsViewModel)
                    .preferredColorScheme(.light)
            } else if mealsViewModel.isShowingDetail {
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
            viewModel.isShowingIngredientsView = false
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
        .onChange(of: viewModel.productionOrder, { oldValue, newValue in
            mealCells = Array(viewModel.productionOrder.keys)
        })
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
                            viewModel.isShowingIngredientsView = true
                        } label: {
                            Image(systemName: "info.circle")
                        }
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

struct IngredientsView: View {
    
    @Environment(\.displayScale) var displayScale
    @EnvironmentObject var viewModel: MenuViewModel
    @EnvironmentObject var mealsViewModel: MealsViewModel
    @State private var ingredients = [IngredientCategory: [Ingredient: [Double]]]()
    @State private var maxCount = 0
    @State private var date = String()
    @State private var exporting = false
    @State private var isMealExporting = false
    @State private var isImage = false
    @State private var activityVC = ActivityViewController(activityItems: [])
    @State private var mealsImage = UIImage()
    @State private var meals = [Meal: Int]()
    @State private var mealsArray = [Meal]()
    @State private var counts = [String]()
    @State private var rows = Int()
    @State private var portionStrings = [String]()
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    viewModel.isShowingIngredientsView = false
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(exporting ? .white:.orange)
                }
                Spacer()
                Button {
                    isMealExporting.toggle()
                } label: {
                    Image(systemName: isMealExporting ? "carrot.fill":"tray.full.fill")
                        .foregroundStyle(exporting ? .white:.orange)
                }
                Button {
                    shareImage()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(exporting ? .white:.orange)
                }
            }
            .padding(.vertical)
            if isMealExporting {
                mealsBody
            } else {
                ingredientsBody
            }
        }
        .padding()
        .preferredColorScheme(.light)
        .onAppear {
            for category in IngredientCategory.allCases {
                ingredients[category] = [:]
            }
            for ingredient in viewModel.ingredients {
                ingredients[ingredient.key.category]![ingredient.key] = ingredient.value
                maxCount = max(maxCount, ingredient.key.ingredients.count)
            }
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            var formatter = DateFormatter()
            formatter.dateFormat = "MM/dd/yyyy"
            date = formatter.string(from: tomorrow)
            let remainder = (viewModel.mealsProductionOrder.count) % 3
            rows = viewModel.mealsProductionOrder.count / 3
            rows += remainder == 0 ? 0:1
            mealsArray = Array(viewModel.mealsProductionOrder.keys)
            counts = Array(viewModel.mealsProductionOrder.values).map { String($0) }
            for meal in mealsArray {
                var portionString = String()
                for portion in meal.portion {
                    portionString += portion.key.name + " " + portion.value
                    if portion.key != Array(meal.portion.keys).last {
                        portionString += " / "
                    }
                }
                portionStrings.append(portionString)
            }
        }
        .sheet(isPresented: $isImage) {
            print("Dismiss")
        } content: {
            activityVC
        }
        .onChange(of: viewModel.mealsProductionOrder) { oldValue, newValue in
            mealsArray = Array(newValue.keys)
            counts = Array(newValue.values).map { String($0) }
            portionStrings = []
            for meal in mealsArray {
                var portionString = String()
                for portion in meal.portion {
                    portionString += portion.key.name + " " + portion.value
                    if portion.key != Array(meal.portion.keys).last {
                        portionString += " / "
                    }
                }
                portionStrings.append(portionString)
            }
        }
        
    }
    
    var ingredientsBody: some View {
        VStack {
            Text("Ingredients of \(date)")
                .font(.title)
                .bold()
                .foregroundStyle(.black)
            ScrollView {
                ScrollView(.horizontal) {
                    ForEach(IngredientCategory.allCases, id: \.self) { category in
                        if !(ingredients[category] ?? [:]).isEmpty {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(category.rawValue)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.black)
                                    Spacer()
                                }
                                ForEach(Array(ingredients[category]!.keys), id: \.self) { ingredient in
                                    VStack {
                                        HStack(spacing: 30) {
                                            VStack {
                                                ZStack {
                                                    RoundedRectangle(cornerSize: CGSize(width: 20, height: 10))
                                                        .fill(category.color)
                                                        .opacity(0.4)
                                                    Text(ingredient.name)
                                                        .fontWeight(.medium)
                                                        .padding(.vertical, 5)
                                                        .foregroundStyle(.black)
                                                }
                                                .frame(width: 200)
                                                Text("\(ingredients[category]![ingredient]![0].forTrailingZero()) Meal\(ingredients[category]![ingredient]![0] == 1 ? "":"s") • \((ingredients[category]![ingredient]![0] * ingredient.quantity).forTrailingZero())\(ingredients[category]![ingredient]![1] == 0 ? "":" + \(ingredients[category]![ingredient]![1]) = \(ingredients[category]![ingredient]![0] + ingredients[category]![ingredient]![1]) \(ingredient.units)")")
                                                    .foregroundStyle(.black)
                                            }
                                            LazyHStack {
                                                ForEach(Array(ingredient.ingredients.keys), id: \.self) { ingred in
                                                    ZStack {
                                                        Rectangle()
                                                            .fill(.clear)
                                                        VStack {
                                                            Text(ingred)
                                                                .fontWeight(.medium)
                                                                .foregroundStyle(.black)
                                                            Text(String(Double(round(10 * ingredient.ingredients[ingred]! * (ingredients[category]![ingredient]![0] + ingredients[category]![ingredient]![1]/ingredient.quantity)) / 10)))
                                                                .foregroundStyle(.black)
                                                        }
                                                    }
                                                    .frame(width: 200)
                                                }
                                                ForEach(Array(ingredient.ingredients.keys).count..<maxCount, id: \.self) { ingred in
                                                    ZStack {
                                                        Rectangle()
                                                            .fill(.clear)
                                                            .frame(width: 200)
                                                    }
                                                }
                                            }
                                            ZStack {
                                                Rectangle()
                                                    .fill(.clear)
                                                VStack {
                                                    Text(ingredient.preparation)
                                                        .font(.system(size: 12))
                                                        .multilineTextAlignment(.center)
                                                        .foregroundStyle(.black)
                                                        .lineLimit(2)
                                                }
                                            }
                                            .frame(width: 300)
                                        }
                                        Rectangle()
                                            .foregroundStyle(.black)
                                            .frame(height: 1)
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
        }
    }
    
    
    
    var mealsBody: some View {
        ZStack {
            Color.white
            VStack {
                Text("Meals of \(date)")
                    .font(.title)
                    .bold()
                    .foregroundStyle(.black)
                ScrollView {
                    ScrollView(.horizontal) {
                        ForEach(0..<rows, id: \.self) { i in
                            LazyHStack {
                                ForEach(i*3..<(i+1)*3, id: \.self) { j in
                                    ZStack {
                                        if j >= mealsArray.count {
                                            Rectangle()
                                                .foregroundStyle(.white)
                                        }
                                        else {
                                            RoundedRectangle(cornerSize: CGSize(width: 20, height: 10))
                                                .foregroundStyle(.white)
                                                .shadow(radius: j < mealsArray.count ? 5: 0)
                                            HStack {
                                                VStack {
                                                    if let image = mealsArray[j].image {
                                                        Image(uiImage: image)
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fit)
                                                            .frame(height: 150)
                                                    } else {
                                                        Image("emptyBox")
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fit)
                                                            .frame(height: 150)
                                                    }
                                                    Text(counts[j])
                                                        .font(.title)
                                                        .bold()
                                                }
                                                VStack {
                                                    Text(mealsArray[j].title)
                                                        .font(.title2)
                                                        .fontWeight(.semibold)
                                                        .multilineTextAlignment(.center)
                                                        .padding(.horizontal, 5)
                                                        .padding(.top, 5)
                                                    Text(mealsArray[j].subtitle)
                                                        .font(.title3)
                                                        .multilineTextAlignment(.center)
                                                        .padding(.horizontal, 5)
                                                    Text(portionStrings[j])
                                                        .multilineTextAlignment(.center)
                                                        .padding(5)
                                                }
                                            }
                                        }
                                    }
                                    .frame(width: 500, height: 300)
                                    .padding()
                                }
                            }
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.light)
    }
    
    
    
    
    private func shareImage() {
        exporting = true
        guard var screenshotImage1 = body.snapshot() else { return }
        isMealExporting.toggle()
        guard var screenshotImage2 = body.snapshot() else { return }
        activityVC = ActivityViewController(activityItems: [screenshotImage1, screenshotImage2])
        isMealExporting.toggle()
        exporting = false
        isImage = true
    }
}
