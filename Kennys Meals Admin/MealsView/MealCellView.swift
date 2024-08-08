//
//  MealCellView.swift
//  Kennys Meals Admin
//
//  Created by Krish on 6/30/24.
//

import SwiftUI
import UIKit
import FirebaseStorage

struct MealCellView: View {
    
    @Binding var mealCell: MealCell
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerSize: CGSize(width: 20, height: 10))
                .foregroundStyle(.clear)
                .shadow(radius: 5)
            HStack(spacing: 10) {
                HStack(spacing: -5) {
                    Rectangle()
                        .fill(mealCell.mealType.color)
                        .frame(width: 3.5)
                        .padding(.vertical, 40)
                    if let mealImage = mealCell.mealImage {
                        Image(uiImage: mealImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(.vertical, 20)
                    } else {
                        Image("emptyBox")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(.vertical, 20)
                    }
                }
                VStack {
                    Text(mealCell.title)
                        .font(.headline)
                        .bold()
                        .foregroundStyle(.black)
                        .minimumScaleFactor(0.01)
                    Text(mealCell.subtitle)
                        .font(.subheadline)
                        .padding(.bottom, 5)
                        .foregroundStyle(.black)
                    Text("\(mealCell.cals) Cal • \(mealCell.carbs)g Carb • \(mealCell.fat)g Fat • \(mealCell.protein)g Protein")
                        .font(.system(size: 10))
                        .foregroundStyle(.black)
                        .padding(.vertical, 7.5)
                }
                Spacer()
            }
            .padding(.horizontal)
        }
        .frame(maxHeight: 150)
        .padding(.horizontal, 5)
    }
}
