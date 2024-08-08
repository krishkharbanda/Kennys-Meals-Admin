//
//  Image++Extension.swift
//  Kennys Meals Admin
//
//  Created by Krish on 7/12/24.
//

import Foundation
import SwiftUI

extension Image {
    func centerCropped() -> some View {
        GeometryReader { geo in
            self
            .resizable()
            .scaledToFill()
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
    }
}

//import UIKit
//import Vision
//import CoreImage.CIFilterBuiltins
//
//var processingQueue = DispatchQueue(label: "ProcessingQueue")
//extension CIImage {
//    public func createSticker() -> UIImage? {
//        var stickerImage: UIImage?
//        processingQueue.async {
//            print("heyy")
//            guard let maskImage = subjectMaskImage(from: self) else {
//                print("Failed to create mask image")
//                return
//            }
//            print("this her")
//            let outputImage = apply(mask: maskImage, to: self)
//            print("first time")
//            let image = render(ciImage: outputImage)
//            print("comin to")
//            DispatchQueue.main.async {
//                print("my house")
//                stickerImage = image
//            }
//        }
//        return stickerImage
//    }
//}
//public func subjectMaskImage(from inputImage: CIImage) -> CIImage? {
//    let handler = VNImageRequestHandler(ciImage: inputImage)
//    let request = VNGenerateForegroundInstanceMaskRequest()
//    do {
//        try handler.perform([request])
//    } catch {
//        print("1", error.localizedDescription)
//        return nil
//    }
//    guard let result = request.results?.first else {
//        print("No observations found")
//        return nil
//    }
//    do {
//        let maskPixelBuffer = try result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler)
//        return CIImage(cvPixelBuffer: maskPixelBuffer)
//    } catch {
//        print("2", error.localizedDescription)
//        return nil
//    }
//}
//public func apply(mask: CIImage, to image: CIImage) -> CIImage {
//    let filter = CIFilter.blendWithMask()
//    filter.inputImage = image
//    filter.maskImage = mask
//    filter.backgroundImage = CIImage.empty()
//    return filter.outputImage!
//}
//public func render(ciImage: CIImage) -> UIImage {
//    guard let cgImage = CIContext(options: nil).createCGImage(ciImage, from: ciImage.extent) else {
//        fatalError("Failed to render CGImage")
//    }
//    return UIImage(cgImage: cgImage)
//}
