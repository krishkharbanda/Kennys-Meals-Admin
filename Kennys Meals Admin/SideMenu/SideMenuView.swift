//
//  SideMenuView.swift
//  Kennys Meals Admin
//
//  Created by Krish on 6/29/24.
//

import SwiftUI
import FirebaseAuth

struct SideMenuView: View {
    
    var name: String
    @Binding var selectedSideMenuTab: Int
    @Binding var presentSideMenu: Bool
    @Binding var appScene: AppScene
    
    var body: some View {
        HStack {
            ZStack {
                Rectangle()
                    .fill(.white)
                    .frame(width: 270)
                    .shadow(color: .white.opacity(0.1), radius: 5, x: 0, y: 3)
                VStack {
                    VStack(alignment: .leading, spacing: 0) {
                        ProfileImageView()
                            .frame(height: 140)
                            .padding(.bottom, 30)
                        ForEach(SideMenuRowType.allCases, id: \.self) { row in
                            RowView(isSelected: selectedSideMenuTab == row.rawValue, imageName: row.iconName, title: row.title) {
                                selectedSideMenuTab = row.rawValue
                                presentSideMenu.toggle()
                            }
                        }
                        Spacer()
                    }
                    Button {
                        do {
                            try Auth.auth().signOut()
                        } catch let signOutError as NSError {
                            print("Error signing out: %@", signOutError)
                        }
                        appScene = .login
                        presentSideMenu = false
                    } label: {
                        Text("Log Out")
                            .bold()
                            .foregroundStyle(.red)
                    }
                    .padding()
                    .padding(.bottom)
                }
                .padding(.top, 100)
                .frame(width: 270)
                .background(Color.orange)
            }
            Spacer()
        }
        .background(.clear)
    }
    
    func ProfileImageView() -> some View {
        VStack(alignment: .center) {
            HStack{
                Spacer()
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.white)
                    .frame(width: 75, height: 75)
                    .overlay(
                        RoundedRectangle(cornerRadius: 50)
                            .stroke(.orange.opacity(0.5), lineWidth: 10)
                    )
                    .cornerRadius(50)
                Spacer()
            }
            
            Text("Welcome, \(name.split(separator: " ")[0])")
                .font(.title2)
                .bold()
                .foregroundColor(.white)
        }
    }
    
    func RowView(isSelected: Bool, imageName: String, title: String, hideDivider: Bool = false, action: @escaping (()->())) -> some View{
        Button{
            action()
        } label: {
            VStack(alignment: .leading){
                HStack(spacing: 20){
                    Rectangle()
                        .fill(isSelected ? .white : .orange)
                        .frame(width: 5)
                    
                    ZStack{
                        Image(systemName: imageName)
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(isSelected ? .white : .white)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 26, height: 26)
                    }
                    .frame(width: 30, height: 30)
                    Text(title)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(isSelected ? .white : .white)
                    Spacer()
                }
            }
        }
        .frame(height: 50)
        .background(
            LinearGradient(colors: [isSelected ? .white.opacity(0.5) : .orange, .orange], startPoint: .leading, endPoint: .trailing)
        )
    }
}
