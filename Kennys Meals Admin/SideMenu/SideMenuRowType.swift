//
//  SideMenuRowType.swift
//  Kennys Meals Admin
//
//  Created by Krish on 6/29/24.
//

import Foundation
enum SideMenuRowType: Int, CaseIterable {
    
    case home = 0
    case meals = 1
    case menus = 2
    
    var title: String {
        switch self {
        case .home:
            return "Home"
        case .meals:
            return "Meals"
        case .menus:
            return "Menus"
        }
    }
    
    var iconName: String {
        switch self {
        case .home:
            return "house.fill"
        case .meals:
            return "fork.knife"
        case .menus:
            return "doc.richtext"
        }
    }
}
