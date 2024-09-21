//
//  HabitatView.swift
//  Kennys Meals Admin
//
//  Created by Krish on 6/22/24.
//

import SwiftUI
import FirebaseFirestore
import FirebaseStorage

struct HabitatView: View {
    
    @EnvironmentObject var habitat: Habitat
    @State var presentSideMenu = false
    @State var selectedSideMenuTab = 0
    
    var body: some View {
        ZStack {
            if habitat.appScene == .login {
                LoginView()
                    .environmentObject(habitat)
                    .preferredColorScheme(.light)
            } else if habitat.appScene == .resetPassword {
                ResetPasswordView()
                    .environmentObject(habitat)
                    .preferredColorScheme(.light)
            } else if habitat.appScene == .home {
                ZStack{
                    TabView(selection: $selectedSideMenuTab) {
                        HomeView(presentSideMenu: $presentSideMenu)
                            .environmentObject(habitat)
                            .preferredColorScheme(.light)
                            .tag(SideMenuRowType.home.rawValue)
                        MealsView(presentSideMenu: $presentSideMenu)
                            .environmentObject(habitat)
                            .preferredColorScheme(.light)
                            .tag(SideMenuRowType.meals.rawValue)
                        MenuView(presentSideMenu: $presentSideMenu)
                            .environmentObject(habitat)
                            .preferredColorScheme(.light)
                            .tag(SideMenuRowType.menus.rawValue)
                    }
                    SideMenu(isShowing: $presentSideMenu, content: AnyView(SideMenuView(name: habitat.user.name, selectedSideMenuTab: $selectedSideMenuTab, presentSideMenu: $presentSideMenu, appScene: $habitat.appScene)))
                }
            }
        }
        .onAppear {
            
        }
    }
}

#Preview {
    HabitatView()
        .environmentObject(Habitat())
}
