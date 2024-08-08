//
//  ScanViewModel.swift
//  Kennys Meals Admin
//
//  Created by Krish on 7/28/24.
//

import Foundation
import SwiftUI
import VisionKit
import AVKit

enum DataScannerAccessStatus {
    case notDetermined
    case cameraAccessNotGranted
    case cameraNotAvailable
    case scannerAvailable
    case scannerNotAvailable
}

@MainActor
final class ScanViewModel: ObservableObject {
    @Published var dataScannerAccessStatus: DataScannerAccessStatus = .notDetermined
    @Published var recognizedItems: [RecognizedItem] = []
    @Published var isShowingScanner = true
    @Published var isMenuSelecting = false
    
    private var isScannerAvailable: Bool {
        DataScannerViewController.isAvailable && DataScannerViewController.isSupported
    }
    
    func requestDataScannerAccessStatus() async {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            dataScannerAccessStatus = .cameraNotAvailable
            return
        }
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            
        case .authorized:
            dataScannerAccessStatus = isScannerAvailable ? .scannerAvailable : .scannerNotAvailable
        case .restricted, .denied:
            dataScannerAccessStatus = .cameraAccessNotGranted
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted {
                dataScannerAccessStatus = isScannerAvailable ? .scannerAvailable : .scannerNotAvailable
            } else {
                dataScannerAccessStatus = .cameraAccessNotGranted
            }
        default:
            break
        }
    }
}
