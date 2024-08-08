//
//  ScanView.swift
//  Kennys Meals Admin
//
//  Created by Krish on 7/28/24.
//

import SwiftUI

struct ScanView: View {
    
    @EnvironmentObject var viewModel: ScanViewModel
    @Binding var selectedSku: Int
    
    var body: some View {
        ZStack {
            Color.orange
                .ignoresSafeArea(.all)
            VStack(spacing: 0) {
                HStack {
                    Button {
                        viewModel.isShowingScanner = false
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.white)
                    }
                    Spacer()
                }
                .padding(.vertical)
                .padding()
                scanView
            }
        }
    }
    
    private var scanView: some View {
        DataScannerView(recognizedItems: $viewModel.recognizedItems, selectedSku: $selectedSku, isMenuSelecting: $viewModel.isMenuSelecting)
    }
}
