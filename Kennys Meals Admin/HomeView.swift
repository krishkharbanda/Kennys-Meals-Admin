//
//  HomeView.swift
//  Kennys Meals Admin
//
//  Created by Krish on 6/26/24.
//

import SwiftUI

struct HomeView: View {
    
    @EnvironmentObject var habitat: Habitat
    @Binding var presentSideMenu: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                HStack{
                    Spacer()
                    Button{
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
}

//#Preview {
//    HomeView()
//        .environmentObject(Habitat())
//}
