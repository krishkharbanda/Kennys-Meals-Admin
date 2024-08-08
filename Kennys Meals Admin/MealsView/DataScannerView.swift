//
//  DataScannerView.swift
//  Kennys Meals Admin
//
//  Created by Krish on 7/28/24.
//

import Foundation
import SwiftUI
import VisionKit

struct DataScannerView: UIViewControllerRepresentable {
    
    @Binding var recognizedItems: [RecognizedItem]
    @Binding var selectedSku: Int
    @Binding var isMenuSelecting: Bool
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let viewController = DataScannerViewController(recognizedDataTypes: [.barcode(symbologies: [.code128])], qualityLevel: .balanced, recognizesMultipleItems: false, isGuidanceEnabled: true, isHighlightingEnabled: true)
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        uiViewController.delegate = context.coordinator
        try? uiViewController.startScanning()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(recognizedItems: $recognizedItems, selectedSku: $selectedSku, isMenuSelecting: $isMenuSelecting)
    }
    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        @Binding var recognizedItems: [RecognizedItem]
        @Binding var selectedSku: Int
        @Binding var isMenuSelecting: Bool
        
        init(recognizedItems: Binding<[RecognizedItem]>, selectedSku: Binding<Int>, isMenuSelecting: Binding<Bool>) {
            self._recognizedItems = recognizedItems
            self._selectedSku = selectedSku
            self._isMenuSelecting = isMenuSelecting
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            print("didTapOn", item)
        }
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            switch addedItems[0] {
            case .text:
                print("text")
            case .barcode(let barcode):
                guard let skuString = barcode.payloadStringValue, let sku = Int(skuString) else { return }
                selectedSku = sku
                dataScanner.stopScanning()
                if !isMenuSelecting {
                    dataScanner.dismiss(animated: true)
                }
            @unknown default:
                print("text")
            }
            //print("didAddItems", addedItems)
        }
        func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            print("didRemoveItems", removedItems)
        }
        func dataScanner(_ dataScanner: DataScannerViewController, becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable) {
            print("became unavailable with error", error.localizedDescription)
        }
    }
}
