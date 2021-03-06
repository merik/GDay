//
//  FaceCropper.swift
//  GDay
//
//  Created by Erik Mai on 28/5/18.
//  Copyright © 2018 dmc. All rights reserved.
//

import Foundation

import UIKit
import Vision

class CroppedImage {
    var image: UIImage?
    var rect: CGRect?
    init(image: UIImage?, rect: CGRect) {
        self.image = image
        self.rect = rect
    }
}

enum FaceCropResult {
    case success([CroppedImage])
    case notFound
    case failure(Error)
}

@available(iOS 11.0, *)

class FaceCropper {
    
    //private var visionRequests:[VNRequest] = []
    //private var faces:[UIImage] = []
    //private var rType: resultType!
    
    let image: UIImage?
    
//    var count:Int {
//        return self.faces.count
//    }
    
    init(image: UIImage?) {
        self.image = image
    }
    func crop(_ completion: @escaping (FaceCropResult) -> Void) {
        
        guard let cgImage = self.image?.fixOrientation().cgImage else {
            completion(.notFound)
            return
        }
        
        let req = VNDetectFaceRectanglesRequest { request, error in
            guard error == nil else {
                completion(.failure(error!))
                return
            }
            
            
            
            let faceImages = request.results?.map({ result -> CroppedImage? in
                guard let face = result as? VNFaceObservation else { return nil }
                
                let paddingWidth = CGFloat(0.2)
                let paddingHeight = CGFloat(0.2)
                
                var width = (face.boundingBox.width + paddingWidth) * CGFloat(cgImage.width)
                if width > CGFloat(cgImage.width) {
                    width = CGFloat(cgImage.width)
                }
                
                var height = (face.boundingBox.height + paddingHeight) * CGFloat(cgImage.height)
                if height > CGFloat(cgImage.height) {
                    height = CGFloat(cgImage.height)
                }
                
                var x = (face.boundingBox.origin.x - paddingWidth/2) * CGFloat(cgImage.width)
                var y = (1 - face.boundingBox.origin.y + paddingHeight/2) * CGFloat(cgImage.height) - height
                
                if x < 0 {
                    x = 0
                }
                if y < 0 {
                    y = 0
                }
                if x + width > CGFloat(cgImage.width) {
                    width = CGFloat(cgImage.width) - x
                }
                if y + height > CGFloat(cgImage.height) {
                    height = CGFloat(cgImage.height) - y
                }
                
                
                
                let croppingRect = CGRect(x: x, y: y, width: width, height: height)
                guard let faceImage = cgImage.cropping(to: croppingRect) else {
                    return nil
                }
                let croppedImage = CroppedImage(image: UIImage(cgImage: faceImage), rect: croppingRect)
                return croppedImage
            }).compactMap { $0 }
            
            guard let result = faceImages, result.count > 0 else {
                completion(.notFound)
                return
            }
            
            completion(.success(result))
        }
        
        do {
            try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([req])
        } catch let error {
            completion(.failure(error))
        }
    }
    
}

