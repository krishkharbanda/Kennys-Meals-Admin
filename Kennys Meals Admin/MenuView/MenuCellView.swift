//
//  MenuCellView.swift
//  Kennys Meals Admin
//
//  Created by Krish on 7/25/24.
//

import SwiftUI

struct MenuCellView: View {
    
    @Binding var menuCell: MenuCell
    @State private var mealTypeCount = String()
    @State private var half = Int()
    @State private var mealCells = [MealCell]()
    @State private var mealCountText = String()
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerSize: CGSize(width: 20, height: 10))
                .foregroundStyle(menuCell.selectedMenu ? .orange : .white)
                .shadow(radius: 5)
            VStack {
                if menuCell.selectedMenu {
                    HStack {
                        Text("SELECTED MENU")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .bold()
                        Spacer()
                    }
                }
                Text(menuCell.docId)
                    .font(.headline)
                    .bold()
                    .foregroundStyle(menuCell.selectedMenu ? .white : .black)
                    .minimumScaleFactor(0.01)
                Text(mealCountText)
                    .font(.subheadline)
                    .foregroundStyle(menuCell.selectedMenu ? .white : .black)
                Text(mealTypeCount)
                    .font(.system(size: 10))
                    .foregroundStyle(menuCell.selectedMenu ? .white : .black)
                    .padding(.vertical, 1.5)
                ScrollView(.horizontal) {
                    LazyHStack(spacing: -5) {
                        ForEach(0..<half, id: \.self) { i in
                            VStack {
                                if let mealImage = mealCells[i].mealImage {
                                    Image(uiImage: mealImage)
                                        .centerCropped()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxHeight: 115)
                                        .padding(.vertical, 3.5)
                                        .shadow(radius: 3)
                                } else {
                                    Image("emptyBox")
                                        .centerCropped()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxHeight: 115)
                                        .padding(.vertical, 3.5)
                                        .shadow(radius: 3)
                                }
                                if i+half != mealCells.count {
                                    if let mealImage = mealCells[i+half].mealImage {
                                        Image(uiImage: mealImage)
                                            .centerCropped()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(maxHeight: 115)
                                            .padding(.vertical, 3.5)
                                            .shadow(radius: 3)
                                    } else {
                                        Image("emptyBox")
                                            .centerCropped()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(maxHeight: 115)
                                            .padding(.vertical, 3.5)
                                            .shadow(radius: 3)
                                    }
                                } else {
                                    Spacer()
                                        .frame(maxHeight: 115)
                                        .padding(.vertical, 3.5)
                                }
                            }
                        }
                        .frame(maxHeight: 220)
                    }
                }
            }
            .padding()
        }
        .frame(height: 250)
        .padding(.horizontal, 5)
        .onAppear {
            mealCountText = "\(menuCell.mealCells.count) Meal\(menuCell.mealCells.count == 1 ? "": "s")"
            mealTypeCount = ""
            mealCells = Array(menuCell.mealCells.keys)
            half = menuCell.mealCells.count / 2
            if menuCell.mealCells.count % 2 == 1 {
                half += 1
            }
            var index = 0
            for count in menuCell.mealTypeCount {
                index += 1
                mealTypeCount += "\(count.value) \(count.key.rawValue)\(index != menuCell.mealTypeCount.count ? " • ":"")"
            }
        }
        .onChange(of: menuCell) { oldValue, newValue in
            mealCountText = "\(menuCell.mealCells.count) Meal\(menuCell.mealCells.count == 1 ? "": "s")"
            mealTypeCount = ""
            mealCells = Array(newValue.mealCells.keys)
            half = newValue.mealCells.count / 2
            if newValue.mealCells.count % 2 == 1 {
                half += 1
            }
            var index = 0
            for count in newValue.mealTypeCount {
                index += 1
                mealTypeCount += "\(count.value) \(count.key.rawValue)\(index != newValue.mealTypeCount.count ? " • ":"")"
            }
        }
    }
}
