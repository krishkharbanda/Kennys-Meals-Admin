//
//  MealDetailView.swift
//  Kennys Meals Admin
//
//  Created by Krish on 7/11/24.
//

import SwiftUI
import UIKit
import FirebaseFirestore
import FirebaseStorage
import PhotosUI

struct MealDetailView: View {
    
    //["title": meal.title, "subtitle": meal.subtitle, "portion": meal.portion, "sku": meal.sku, "barcodeConversion": meal.barcodeConversion, "mealInstructions": meal.mealInstructions, "instructions": meal.instructions, "ingredients": meal.ingredients, "contains": meal.contains, "imageTag": meal.mealType.rawValue, "servingSize": meal.nutritionFacts.servingSize, "calories": meal.nutritionFacts.calories, "totalFat": meal.nutritionFacts.totalFat, "totalFatPercentage": meal.nutritionFacts.totalFatPercentage, "saturatedFat": meal.nutritionFacts.satFat, "saturatedFatPercentage": meal.nutritionFacts.satFatPercentage, "transFat": meal.nutritionFacts.transFat, "transFatPercentage": meal.nutritionFacts.transFatPercentage, "cholestrol": meal.nutritionFacts.cholesterol, "cholestrolPercentage": meal.nutritionFacts.cholesterolPercentage, "sodium": meal.nutritionFacts.sodium, "sodiumPercentage": meal.nutritionFacts.sodiumPercentage, "potassium": meal.nutritionFacts.potassium, "potassiumPercentage": meal.nutritionFacts.potassiumPercentage, "carbohydrate": meal.nutritionFacts.totalCarb, "carbohydratePercentage": meal.nutritionFacts.totalCarbPercentage, "fiber": meal.nutritionFacts.fiber, "fiberPercentage": meal.nutritionFacts.fiberPercentage, "sugars": meal.nutritionFacts.totalSugar, "addedSugars": meal.nutritionFacts.addedSugars, "protein": meal.nutritionFacts.protein, "proteinPercentage": meal.nutritionFacts.proteinPercentage, "calcium": meal.nutritionFacts.calcium, "calciumPercentage": meal.nutritionFacts.calciumPercentage, "vitaminD": meal.nutritionFacts.vitD, "vitaminDPercentage": meal.nutritionFacts.vitDPercentage, "iron": meal.nutritionFacts.iron, "ironPercentage": meal.nutritionFacts.ironPercentage]
    
    @EnvironmentObject var viewModel: MealsViewModel
    @Binding var meal: Meal
    @State private var image: UIImage?
    @State private var isEditing = false
    @State private var tempMeal = Meal()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isPhotoError = false
    @State private var isUploadError = false
    @State private var changes: [String: Any] = [:]
    @State private var isEmpty = false
    @State private var isEmptyError = false
    @State private var fat = String()
    @State private var carbs = String()
    @State private var protein = String()
    
    var body: some View {
        VStack {
            VStack {
                HStack {
                    Button {
                        viewModel.isShowingDetail = false
                    } label: {
                        Image(systemName: viewModel.viewingMealFromMenu ? "chevron.left":"xmark")
                    }
                    Spacer()
                    if viewModel.canWrite {
                        Button {
                            if !isEditing {
                                tempMeal = meal
                            } else {
                                if !changes.isEmpty {
                                    print(changes)
                                    var changePercents = [String: Int]()
                                    for change in changes {
                                        print(change)
                                        if change.key == "transFat" {
                                            print(change.value)
                                            guard let value = change.value as? String else {
                                                print("1")
                                                isUploadError = true
                                                return
                                            }
                                            print(value)
                                            guard var mg = Double(value) else {
                                                print("2")
                                                isUploadError = true
                                                return
                                            }
                                            mg *= 1000
                                            print(mg)
                                            var percent = mg / Double(NutrientDVs.transFat)
                                            percent *= 100
                                            changePercents["transFatPercentage"] = Int(percent)
                                        } else if change.key == "calories" && change.key == "sugars" && change.key == "addedSugars" {} else {
                                            guard let value = change.value as? String else {
                                                isUploadError = true
                                                return
                                            }
                                            guard let doub = Double(value) else {
                                                isUploadError = true
                                                return
                                            }
                                            var percent = doub / Double(NutrientDVs.returnValue(field: change.key))
                                            percent *= 100
                                            changePercents["\(change.key)Percentage"] = Int(percent)
                                        }
                                    }
                                    for changePercent in changePercents {
                                        changes[changePercent.key] = changePercent.value
                                    }
                                    Firestore.firestore().collection("Meals").document(meal.docId).setData(changes, merge: true) { error in
                                        if let error = error {
                                            print(error.localizedDescription)
                                            return
                                        }
                                    }
                                }
                                guard let newImage = image else {
                                    Firestore.firestore().collection("Meals").document(meal.docId).getDocument { documentSnapshot, error in
                                        if let error = error {
                                            print(error.localizedDescription)
                                            return
                                        }
                                        if let documentSnapshot = documentSnapshot {
                                            var instructions: [String]?
                                            if let instructionArray = documentSnapshot.get("instructions") {
                                                if let nsinstructions = instructionArray as? NSArray, let instructionsArray = nsinstructions as? [String] {
                                                    instructions = instructionsArray
                                                }
                                            }
                                            let nutritionFacts = NutritionFacts(servingSize: documentSnapshot.get("servingSize") as! Int, calories: documentSnapshot.get("calories") as! Int, totalFat: documentSnapshot.get("servingSize") as! Int, totalFatPercentage: documentSnapshot.get("totalFatPercentage") as! Int, satFat: documentSnapshot.get("saturatedFat") as! Double, satFatPercentage: documentSnapshot.get("saturatedFatPercentage") as! Int, transFat: documentSnapshot.get("transFat") as! Double, transFatPercentage: documentSnapshot.get("transFatPercentage") as! Int, cholesterol: documentSnapshot.get("cholestrol") as! Int, cholesterolPercentage: documentSnapshot.get("cholestrolPercentage") as! Int, sodium: documentSnapshot.get("sodium") as! Int, sodiumPercentage: documentSnapshot.get("sodiumPercentage") as! Int, potassium: documentSnapshot.get("potassium") as! Int, potassiumPercentage: documentSnapshot.get("potassiumPercentage") as! Int, totalCarb: documentSnapshot.get("carbohydrate") as! Int, totalCarbPercentage: documentSnapshot.get("carbohydratePercentage") as! Int, fiber: documentSnapshot.get("fiber") as! Double, fiberPercentage: documentSnapshot.get("fiberPercentage") as! Int, totalSugar: documentSnapshot.get("sugars") as! Double, addedSugars: documentSnapshot.get("addedSugars") as! Double, protein: documentSnapshot.get("protein") as! Int, proteinPercentage: documentSnapshot.get("proteinPercentage") as! Int, calcium: documentSnapshot.get("calcium") as! Int, calciumPercentage: documentSnapshot.get("calciumPercentage") as! Int, vitD: documentSnapshot.get("vitaminD") as! Double, vitDPercentage: documentSnapshot.get("vitaminDPercentage") as! Int, iron: documentSnapshot.get("iron") as! Double, ironPercentage: documentSnapshot.get("ironPercentage") as! Int)
                                            var portion = [Ingredient: String]()
                                            let portionDict = documentSnapshot.get("portion") as! [String: String]
                                            for portionPair in portionDict {
                                                portion[Ingredient(name: portionPair.key)] = portionPair.value
                                            }
                                            meal = Meal(docId: meal.docId, title: documentSnapshot.get("title") as! String, subtitle: documentSnapshot.get("subtitle") as! String, mealType: MealType(rawValue: documentSnapshot.get("imageTag") as! String)!, nutritionFacts: nutritionFacts, ingredients: documentSnapshot.get("ingredients") as! String, portion: portion, instructions: instructions ?? [], mealInstructions: documentSnapshot.get("mealInstructions") as! String, contains: documentSnapshot.get("contains") as! String, barcodeConversion: documentSnapshot.get("barcodeConversion") as! String, sku: documentSnapshot.get("sku") as! Int, image: self.image ?? nil)
                                            tempMeal = meal
                                            viewModel.editedMeal = true
                                        }
                                    }
                                    return
                                }
                                guard let tempImage = tempMeal.image else {
                                    let pathReference = Storage.storage().reference(withPath: "/resizedMeals")
                                    pathReference.child("/\(meal.docId)").putData(newImage.scale(newWidth: 1024).pngData()!, metadata: nil) { metadata, error in
                                        if let error = error {
                                            print(error.localizedDescription)
                                            return
                                        }
                                        guard let metadata = metadata else {
                                            print("metadata empty")
                                            return
                                        }
                                        print(metadata)
                                    }
                                    return
                                }
                                if newImage != tempImage {
                                    let pathReference = Storage.storage().reference(withPath: "/resizedMeals")
                                    pathReference.child("/\(meal.docId)").putData(newImage.scale(newWidth: 1024).pngData()!, metadata: nil) { metadata, error in
                                        if let error = error {
                                            print(error.localizedDescription)
                                            return
                                        }
                                        guard let metadata = metadata else {
                                            print("metadata empty")
                                            return
                                        }
                                        print(metadata)
                                    }
                                }
                                Firestore.firestore().collection("Meals").document(meal.docId).getDocument { documentSnapshot, error in
                                    if let error = error {
                                        print(error.localizedDescription)
                                        return
                                    }
                                    if let documentSnapshot = documentSnapshot {
                                        var instructions: [String]?
                                        if let instructionArray = documentSnapshot.get("instructions") {
                                            if let nsinstructions = instructionArray as? NSArray, let instructionsArray = nsinstructions as? [String] {
                                                instructions = instructionsArray
                                            }
                                        }
                                        let nutritionFacts = NutritionFacts(servingSize: documentSnapshot.get("servingSize") as! Int, calories: documentSnapshot.get("calories") as! Int, totalFat: documentSnapshot.get("servingSize") as! Int, totalFatPercentage: documentSnapshot.get("totalFatPercentage") as! Int, satFat: documentSnapshot.get("saturatedFat") as! Double, satFatPercentage: documentSnapshot.get("saturatedFatPercentage") as! Int, transFat: documentSnapshot.get("transFat") as! Double, transFatPercentage: documentSnapshot.get("transFatPercentage") as! Int, cholesterol: documentSnapshot.get("cholestrol") as! Int, cholesterolPercentage: documentSnapshot.get("cholestrolPercentage") as! Int, sodium: documentSnapshot.get("sodium") as! Int, sodiumPercentage: documentSnapshot.get("sodiumPercentage") as! Int, potassium: documentSnapshot.get("potassium") as! Int, potassiumPercentage: documentSnapshot.get("potassiumPercentage") as! Int, totalCarb: documentSnapshot.get("carbohydrate") as! Int, totalCarbPercentage: documentSnapshot.get("carbohydratePercentage") as! Int, fiber: documentSnapshot.get("fiber") as! Double, fiberPercentage: documentSnapshot.get("fiberPercentage") as! Int, totalSugar: documentSnapshot.get("sugars") as! Double, addedSugars: documentSnapshot.get("addedSugars") as! Double, protein: documentSnapshot.get("protein") as! Int, proteinPercentage: documentSnapshot.get("proteinPercentage") as! Int, calcium: documentSnapshot.get("calcium") as! Int, calciumPercentage: documentSnapshot.get("calciumPercentage") as! Int, vitD: documentSnapshot.get("vitaminD") as! Double, vitDPercentage: documentSnapshot.get("vitaminDPercentage") as! Int, iron: documentSnapshot.get("iron") as! Double, ironPercentage: documentSnapshot.get("ironPercentage") as! Int)
                                        var portion = [Ingredient: String]()
                                        let portionDict = documentSnapshot.get("portion") as! [String: String]
                                        for portionPair in portionDict {
                                            portion[Ingredient(name: portionPair.key)] = portionPair.value
                                        }
                                        meal = Meal(docId: meal.docId, title: documentSnapshot.get("title") as! String, subtitle: documentSnapshot.get("subtitle") as! String, mealType: MealType(rawValue: documentSnapshot.get("imageTag") as! String)!, nutritionFacts: nutritionFacts, ingredients: documentSnapshot.get("ingredients") as! String, portion: portion, instructions: instructions ?? [], mealInstructions: documentSnapshot.get("mealInstructions") as! String, contains: documentSnapshot.get("contains") as! String, barcodeConversion: documentSnapshot.get("barcodeConversion") as! String, sku: documentSnapshot.get("sku") as! Int, image: self.image ?? nil)
                                        tempMeal = meal
                                        viewModel.editedMeal = true
                                    }
                                }
                            }
                            isEditing.toggle()
                        } label: {
                            Text(isEditing ? "Done":"Edit")
                        }
                        .disabled(isEmpty)
                        if isEditing {
                            Button {
                                changes = [:]
                                meal = tempMeal
                                image = tempMeal.image
                                isEditing = false
                            } label: {
                                Text("Cancel")
                                    .foregroundStyle(.red)
                            }
                            .padding(.leading)
                        }
                    }
                }
                .padding(.vertical)
                TextField("title", text: $meal.title, axis: .vertical)
                    .font(.title)
                    .bold()
                    .multilineTextAlignment(.center)
                    .disabled(!isEditing)
                    .onChange(of: meal.title) { oldValue, newValue in
                        if newValue == tempMeal.title {
                            changes["title"] = nil
                        } else {
                            changes["title"] = newValue
                        }
                    }
                    .lineLimit(3)
                TextField("subtitle", text: $meal.subtitle, axis: .vertical)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .disabled(!isEditing)
                    .onChange(of: meal.subtitle) { oldValue, newValue in
                        if newValue == tempMeal.subtitle {
                            changes["subtitle"] = nil
                        } else {
                            changes["subtitle"] = newValue
                        }
                    }
                    .lineLimit(3)
            }
            .padding()
            HStack {
                HStack(spacing: -5) {
                    Menu {
                        Picker("Meal Type", selection: $meal.mealType) {
                            ForEach(MealType.allCases) { mealType in
                                Text(mealType.rawValue)
                            }
                        }
                    } label: {
                        ZStack {
                            Rectangle()
                                .foregroundStyle(meal.mealType.color)
                                .frame(maxWidth: 10, maxHeight: 140)
                                .padding(.trailing, 10)
                            RoundedRectangle(cornerSize: CGSize(width: 20, height: 10))
                                .foregroundStyle(meal.mealType.color)
                                .frame(maxWidth: 20, maxHeight: 140)
                        }
                    }
                    .onChange(of: meal.mealType) { oldValue, newValue in
                        if newValue == tempMeal.mealType {
                            changes["imageTag"] = nil
                        } else {
                            changes["imageTag"] = newValue
                        }
                    }
                    PhotosPicker(selection: $selectedPhoto, matching: .images, preferredItemEncoding: .automatic) {
                        if let image = image {
                            Image(uiImage: image)
                                .centerCropped()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 170)
                        } else {
                            Image("emptyBox")
                                .centerCropped()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 170)
                        }
                    }
                    .task(id: selectedPhoto) {
                        if isEditing {
                            var data: Data?
                            do {
                                data = try await selectedPhoto?.loadTransferable(type: Data.self)
                            } catch {
                                print(error.localizedDescription)
                                return
                            }
                            guard let data = data else {
                                isPhotoError = true
                                return
                            }
                            image = UIImage(data: data)
                        }
                    }
                }
                HStack {
                    VStack(alignment: .trailing, spacing: 10) {
                        TextField("---", text: $meal.nutritionFacts.calories.toString)
                            .font(.title3)
                            .bold()
                            .multilineTextAlignment(.center)
                            .disabled(!isEditing)
                            .onChange(of: meal.nutritionFacts.calories) { oldValue, newValue in
                                if newValue == tempMeal.nutritionFacts.calories {
                                    changes["calories"] = nil
                                } else {
                                    changes["calories"] = newValue
                                }
                            }
                        TextField("--", text: $meal.nutritionFacts.totalFat.toString)
                            .font(.headline)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .disabled(!isEditing)
                            .onChange(of: meal.nutritionFacts.totalFat) { oldValue, newValue in
                                if newValue == tempMeal.nutritionFacts.totalFat {
                                    changes["totalFat"] = nil
                                } else {
                                    changes["totalFat"] = newValue
                                }
                            }
                        TextField("--", text: $meal.nutritionFacts.totalCarb.toString)
                            .font(.headline)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .disabled(!isEditing)
                            .onChange(of: meal.nutritionFacts.totalCarb) { oldValue, newValue in
                                if newValue == tempMeal.nutritionFacts.totalCarb {
                                    changes["carbohydrate"] = nil
                                } else {
                                    changes["carbohydrate"] = newValue
                                }
                            }
                        TextField("--", text: $meal.nutritionFacts.protein.toString)
                            .font(.headline)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .disabled(!isEditing)
                            .onChange(of: meal.nutritionFacts.protein) { oldValue, newValue in
                                if newValue == tempMeal.nutritionFacts.protein {
                                    changes["protein"] = nil
                                } else {
                                    changes["protein"] = newValue
                                }
                            }
                    }
                    .frame(maxWidth: 60)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Calories")
                            .font(.title3)
                            .bold()
                        Text("Fat")
                            .font(.headline)
                            .fontWeight(.medium)
                        Text("Carbohydrates")
                            .font(.headline)
                            .fontWeight(.medium)
                        Text("Protein")
                            .font(.headline)
                            .fontWeight(.medium)
                    }
                }
                Spacer()
            }
            .disabled(!isEditing)
            ScrollView {
                VStack {
                    HStack(spacing: 10) {
                        LipidsDetailView(meal: $meal, tempMeal: tempMeal, changes: $changes, isEditing: $isEditing)
                        CarbsDetailView(meal: $meal, tempMeal: tempMeal, changes: $changes, isEditing: $isEditing)
                        MineralsDetailView(meal: $meal, tempMeal: tempMeal, changes: $changes, isEditing: $isEditing)
                    }
                    MiscDetailView(meal: $meal, tempMeal: tempMeal, changes: $changes, isEditing: $isEditing)
                }
                .padding()
                VStack {
                    Text("Ingredients")
                        .fontWeight(.medium)
                    TextField("ingredients", text: $meal.ingredients, axis: .vertical)
                        .multilineTextAlignment(.center)
                        .disabled(!isEditing)
                        .lineLimit(6)
                }
                .padding(.horizontal)
                VStack {
                    Text("Portions")
                        .fontWeight(.medium)
                    ForEach(Array(meal.portion.keys), id: \.self) { ingredient in
                        HStack {
                            Text("\(ingredient.name):")
                            Text(meal.portion[ingredient]!)
                        }
                    }
                }
                .padding()
                Text("Instructions")
                    .fontWeight(.medium)
                ForEach(meal.instructions, id: \.self) { instruction in
                    Text("\(meal.instructions.first! == instruction ? "1":"2"). " + instruction)
                }
                //.padding(.horizontal)
            }
        }
        .onTapGesture {
            self.hideKeyboard()
        }
        .alert("Error Selecting Photo", isPresented: $isPhotoError, actions: {
            Button{isPhotoError = false} label: { Text("Ok") }
        }, message: {
            Text("Something went wrong. Please try again.")
        })
        .alert("Error Editing Meal", isPresented: $isUploadError, actions: {
            Button{isUploadError = false} label: { Text("Ok") }
        }, message: {
            Text("Something went wrong. Please try again.")
        })
//        .alert("Field is Empty", isPresented: $isEmptyError, actions: {
//            Button{isEmptyError = false} label: { Text("Ok")}
//        }, message: {
//            Text("Make sure all fields are filled before pressing done.")
//        })
//        .onChange(of: changes, { oldValue, newValue in
//            for val in newValue {
//                if val.value == nil {
//                    isEmpty = true
//                    isEmptyError = true
//                    break
//                }
//            }
//        })
        .onAppear {
            if let fimage = meal.image {
                self.image = fimage
            }
            print(viewModel.isShowingDetail)
        }
        .onDisappear {
            if isEditing {
                meal = tempMeal
            }
            viewModel.isShowingDetail = false
        }
    }
    
}
struct LipidsDetailView: View {
    
    @Binding var meal: Meal
    @State var tempMeal: Meal
    @Binding var changes: [String: Any]
    @Binding var isEditing: Bool
    @State private var satFat = String()
    @State private var transFat = String()
    @State private var cholesterol = String()
    
    var body: some View {
        VStack(spacing: 5) {
            Text("Lipids")
                .fontWeight(.medium)
            HStack {
                VStack(alignment: .trailing, spacing: 5) {
                    TextField("-.-", text: $satFat)
                        .font(.caption)
                        .multilineTextAlignment(.trailing)
                        .disabled(!isEditing)
                        .onChange(of: satFat) { oldValue, newValue in
                            if isEditing {
                                meal.nutritionFacts.satFat.toString = newValue
                                if meal.nutritionFacts.satFat == tempMeal.nutritionFacts.satFat {
                                    changes["saturatedFat"] = nil
                                } else {
                                    changes["saturatedFat"] = meal.nutritionFacts.satFat
                                }
                            }
                        }
                    TextField("-.-", text: $transFat)
                        .font(.caption)
                        .multilineTextAlignment(.trailing)
                        .disabled(!isEditing)
                        .onChange(of: transFat) { oldValue, newValue in
                            if isEditing {
                                meal.nutritionFacts.transFat.toString = newValue
                                if meal.nutritionFacts.transFat == tempMeal.nutritionFacts.transFat {
                                    changes["transFat"] = nil
                                } else {
                                    changes["transFat"] = meal.nutritionFacts.transFat
                                }
                            }
                        }
                    TextField("---", text: $cholesterol)
                        .font(.caption)
                        .multilineTextAlignment(.trailing)
                        .disabled(!isEditing)
                        .onChange(of: cholesterol) { oldValue, newValue in
                            if isEditing {
                                meal.nutritionFacts.cholesterol.toString = newValue
                                if meal.nutritionFacts.cholesterol == tempMeal.nutritionFacts.cholesterol {
                                    changes["cholestrol"] = nil
                                } else {
                                    changes["cholestrol"] = meal.nutritionFacts.cholesterol
                                }
                            }
                        }
                }
                .frame(maxWidth: 40)
                .onAppear {
                    satFat = meal.nutritionFacts.satFat.toString + "g"
                    if meal.nutritionFacts.transFat > 0 && meal.nutritionFacts.transFat < 1 {
                        transFat = String(meal.nutritionFacts.transFat * 1000) + "mg"
                    } else {
                        transFat = meal.nutritionFacts.transFat.toString + "g"
                    }
                    cholesterol = meal.nutritionFacts.cholesterol.toString + "mg"
                }
                .onChange(of: isEditing) { oldValue, newValue in
                    if newValue {
                        satFat = meal.nutritionFacts.satFat.toString
                        transFat = meal.nutritionFacts.transFat.toString
                        cholesterol = meal.nutritionFacts.cholesterol.toString
                    } else {
                        satFat = meal.nutritionFacts.satFat.toString + "g"
                        if meal.nutritionFacts.transFat > 0 && meal.nutritionFacts.transFat < 1 {
                            transFat = String(meal.nutritionFacts.transFat * 1000) + "mg"
                        } else {
                            transFat = meal.nutritionFacts.transFat.toString + "g"
                        }
                        cholesterol = meal.nutritionFacts.cholesterol.toString + "mg"
                    }
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text("Sat Fat")
                        .font(.caption)
                    Text("Trans Fat")
                        .font(.caption)
                    Text("Cholesterol")
                        .font(.caption)
                }
            }
        }
    }
}
struct CarbsDetailView: View {
    
    @Binding var meal: Meal
    @State var tempMeal: Meal
    @Binding var changes: [String: Any]
    @Binding var isEditing: Bool
    @State private var fiber = String()
    @State private var totalSugar = String()
    @State private var addedSugars = String()
    
    var body: some View {
        VStack(spacing: 5) {
            Text("Carbs")
                .fontWeight(.medium)
            HStack {
                VStack(alignment: .trailing, spacing: 5) {
                    TextField("-.-", text: $fiber)
                        .font(.caption)
                        .multilineTextAlignment(.trailing)
                        .disabled(!isEditing)
                        .onChange(of: fiber) { oldValue, newValue in
                            if isEditing {
                                meal.nutritionFacts.fiber.toString = newValue
                                if tempMeal.nutritionFacts.fiber == meal.nutritionFacts.fiber {
                                    changes["fiber"] = nil
                                } else {
                                    changes["fiber"] = meal.nutritionFacts.fiber
                                }
                            }
                        }
                    TextField("-.-", text: $totalSugar)
                        .font(.caption)
                        .multilineTextAlignment(.trailing)
                        .disabled(!isEditing)
                        .onChange(of: totalSugar) { oldValue, newValue in
                            if isEditing {
                                meal.nutritionFacts.totalSugar.toString = newValue
                                if tempMeal.nutritionFacts.totalSugar == meal.nutritionFacts.totalSugar {
                                    changes["sugars"] = nil
                                } else {
                                    changes["sugars"] = meal.nutritionFacts.totalSugar
                                }
                            }
                        }
                    TextField("-.-", text: $addedSugars)
                        .font(.caption)
                        .multilineTextAlignment(.trailing)
                        .disabled(!isEditing)
                        .onChange(of: addedSugars) { oldValue, newValue in
                            if isEditing {
                                meal.nutritionFacts.addedSugars.toString = newValue
                                if tempMeal.nutritionFacts.addedSugars == meal.nutritionFacts.addedSugars {
                                    changes["addedSugars"] = nil
                                } else {
                                    changes["addedSugars"] = meal.nutritionFacts.addedSugars
                                }
                            }
                        }
                }
                .frame(maxWidth: 45)
                .onAppear {
                    fiber = meal.nutritionFacts.fiber.toString + "g"
                    totalSugar = meal.nutritionFacts.totalSugar.toString + "g"
                    addedSugars = meal.nutritionFacts.addedSugars.toString + "g"
                }
                .onChange(of: isEditing) { oldValue, newValue in
                    if newValue {
                        fiber = meal.nutritionFacts.fiber.toString
                        totalSugar = meal.nutritionFacts.totalSugar.toString
                        addedSugars = meal.nutritionFacts.addedSugars.toString
                    } else {
                        fiber = meal.nutritionFacts.fiber.toString + "g"
                        totalSugar = meal.nutritionFacts.totalSugar.toString + "g"
                        addedSugars = meal.nutritionFacts.addedSugars.toString + "g"
                    }
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text("Fiber")
                        .font(.caption)
                    Text("Sugar")
                        .font(.caption)
                    Text("Added Sugar")
                        .font(.caption)
                }
            }
        }
    }
}
struct MineralsDetailView: View {
    
    @Binding var meal: Meal
    @State var tempMeal: Meal
    @Binding var changes: [String: Any]
    @Binding var isEditing: Bool
    @State private var calcium = String()
    @State private var iron = String()
    @State private var sodium = String()
    
    var body: some View {
        VStack(spacing: 5) {
            Text("Minerals")
                .fontWeight(.medium)
            HStack {
                VStack(alignment: .trailing, spacing: 5) {
                    TextField("--", text: $calcium)
                        .font(.caption)
                        .multilineTextAlignment(.trailing)
                        .disabled(!isEditing)
                        .onChange(of: calcium) { oldValue, newValue in
                            if isEditing {
                                meal.nutritionFacts.calcium.toString = newValue
                                if tempMeal.nutritionFacts.calcium == meal.nutritionFacts.calcium {
                                    changes["calcium"] = nil
                                } else {
                                    changes["calcium"] = meal.nutritionFacts.calcium
                                }
                            }
                        }
                    TextField("-.-", text: $iron)
                        .font(.caption)
                        .multilineTextAlignment(.trailing)
                        .disabled(!isEditing)
                        .onChange(of: iron) { oldValue, newValue in
                            if isEditing {
                                meal.nutritionFacts.iron.toString = newValue
                                if tempMeal.nutritionFacts.iron == meal.nutritionFacts.iron {
                                    changes["iron"] = nil
                                } else {
                                    changes["iron"] = meal.nutritionFacts.iron
                                }
                            }
                        }
                    TextField("---", text: $sodium)
                        .font(.caption)
                        .multilineTextAlignment(.trailing)
                        .disabled(!isEditing)
                        .onChange(of: sodium) { oldValue, newValue in
                            if isEditing {
                                meal.nutritionFacts.sodium.toString = newValue
                                if tempMeal.nutritionFacts.sodium == meal.nutritionFacts.sodium {
                                    changes["sodium"] = nil
                                } else {
                                    changes["sodium"] = meal.nutritionFacts.sodium
                                }
                            }
                        }
                }
                .frame(maxWidth: 45)
                .onAppear {
                    calcium = meal.nutritionFacts.calcium.toString + "mg"
                    iron = meal.nutritionFacts.iron.toString + "mg"
                    sodium = meal.nutritionFacts.sodium.toString + "mg"
                }
                .onChange(of: isEditing) { oldValue, newValue in
                    if newValue {
                        calcium = meal.nutritionFacts.calcium.toString
                        iron = meal.nutritionFacts.iron.toString
                        sodium = meal.nutritionFacts.sodium.toString
                    } else {
                        calcium = meal.nutritionFacts.calcium.toString + "mg"
                        iron = meal.nutritionFacts.iron.toString + "mg"
                        sodium = meal.nutritionFacts.sodium.toString + "mg"
                    }
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text("Calcium")
                        .font(.caption)
                    Text("Iron")
                        .font(.caption)
                    Text("Sodium")
                        .font(.caption)
                }
            }
        }
    }
}
struct MiscDetailView: View {
    
    @Binding var meal: Meal
    @State var tempMeal: Meal
    @Binding var changes: [String: Any]
    @Binding var isEditing: Bool
    @State private var vitD = String()
    @State private var potassium = String()
    
    var body: some View {
        HStack(spacing: 10) {
            HStack {
                TextField("-.-", text: $vitD)
                    .font(.caption)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 45)
                    .disabled(!isEditing)
                    .onChange(of: vitD) { oldValue, newValue in
                        if isEditing {
                            meal.nutritionFacts.vitD.toString = newValue
                            if tempMeal.nutritionFacts.vitD == meal.nutritionFacts.vitD {
                                changes["vitaminD"] = nil
                            } else {
                                changes["vitaminD"] = meal.nutritionFacts.vitD
                            }
                        }
                    }
                Text("Vitamin D")
                    .font(.caption)
            }
            .padding(.horizontal)
            HStack {
                TextField("---", text: $potassium)
                    .font(.caption)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 45)
                    .disabled(!isEditing)
                    .onChange(of: potassium) { oldValue, newValue in
                        if isEditing {
                            meal.nutritionFacts.potassium.toString = newValue
                            if tempMeal.nutritionFacts.potassium == meal.nutritionFacts.potassium {
                                changes["potassium"] = nil
                            } else {
                                changes["potassium"] = meal.nutritionFacts.potassium
                            }
                        }
                    }
                Text("Potassium")
                    .font(.caption)
            }
            .padding(.horizontal)
        }
        .onAppear {
            vitD = meal.nutritionFacts.vitD.toString + "mcg"
            potassium = meal.nutritionFacts.potassium.toString + "mg"
        }
        .onChange(of: isEditing) { oldValue, newValue in
            if newValue {
                vitD = meal.nutritionFacts.vitD.toString
                potassium = meal.nutritionFacts.potassium.toString
            } else {
                vitD = meal.nutritionFacts.vitD.toString + "mcg"
                potassium = meal.nutritionFacts.potassium.toString + "mg"
            }
        }
    }
}
