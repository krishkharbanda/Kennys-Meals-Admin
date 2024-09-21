//
//  View++Extension.swift
//  Kennys Meals Admin
//
//  Created by Krish on 6/25/24.
//

import Foundation
import SwiftUI

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
struct SizeCalculator: ViewModifier {
    
    @Binding var size: CGSize
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            size = proxy.size
                        }
                }
            )
    }
}

extension View {
    func saveSize(in size: Binding<CGSize>) -> some View {
        modifier(SizeCalculator(size: size))
    }
    
    func snapshot() -> UIImage? {
        let controller = UIHostingController(
            rootView: self.ignoresSafeArea().fixedSize(horizontal: true, vertical: true))
        guard let view = controller.view else {
            print("view")
            return nil
        }
    
        let targetSize = view.intrinsicContentSize
        if targetSize.width <= 0 || targetSize.height <= 0 {
            print(targetSize)
            return nil
        }
    
        view.bounds = CGRect(origin: .zero, size: targetSize)
        view.backgroundColor = .white
    
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { rendereContext in
            view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}
