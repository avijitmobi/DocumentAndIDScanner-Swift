//
//  SmartImageDetect.swift
//
//  SmartImageDetect
//  Created by Avijit Babu on 08/04/20.
//  Inspired from Arthur
//

import UIKit
import Vision
import CoreImage

extension NSObject: ImageCroppable {}
extension CGImage: ImageCroppable {}
public protocol ImageCroppable {}

/**
 This enumeration is for identification of detection type
 
 - face: for cropping faces
 - barcode: for croping barcodes
 - text: for cropping text rectangles
 */
enum DetectionType {
    case face
    case barcode
    case text
}

/**
 This enumeration is for identification of request type
 
 - success: successfuly cropted objects
 - notFound: not found some object of `DetectionType` in image
 - failure: failed with error
 */

enum SmartDetectResult<T> {
    case success([T])
    case notFound
    case failure(Error)
}

struct SmartImageDetect<T> {
    let detectable: T
    init(_ detectable: T) {
        self.detectable = detectable
    }
}

extension ImageCroppable {
    var detector: SmartImageDetect<Self> {
        return SmartImageDetect(self)
    }
}

extension SmartImageDetect where T: CGImage {
    
    /**
     To crop object in image
     - parameter type: type of object that must be croped
     - parameter completion: callbeck with `ImageDetectResult<T>` with error or success response
     */
    func crop(type: DetectionType, completion: @escaping (SmartDetectResult<CGImage>) -> Void) {
        switch type {
        case .face:
            cropFace(completion)
        case .barcode:
            cropBarcode(completion)
        case .text:
            cropText(completion)
            break
        }
    }
    
    private func cropFace(_ completion: @escaping (SmartDetectResult<CGImage>) -> Void) {
        guard #available(iOS 11.0, *) else {
            completion(.failure(NSError(domain: "Error", code: -1000, userInfo: ["OS Error" : "Os is below 11.0"])))
            return
        }
        let documentImage = CIImage(cgImage: self.detectable)
        let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: CIContext(), options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])!

        let faces = faceDetector.features(in: documentImage)
        var myFaces = [CGImage]()
        for face in faces{
            let increasedFaceBounds = face.bounds.insetBy(dx: -60, dy: -60)
            let faceImage = documentImage.cropped(to: increasedFaceBounds)
            guard let cgImage = CIContext().createCGImage(faceImage, from: faceImage.extent) else {
                completion(.notFound)
                return
            }
            myFaces.append(cgImage)
        }
        if myFaces.count == 0 {
            let req = VNDetectFaceRectanglesRequest { request, error in
                guard error == nil else {
                    completion(.failure(error!))
                    return
                }
                
                let faceImages = request.results?.map({ result -> CGImage? in
                    guard let face = result as? VNFaceObservation else { completion(.failure(NSError(domain: "Error", code: -1000, userInfo: ["Image Error" : "Image not converted"]))); return nil }
                    let faceImage = self.cropImage(object: face)
                    return faceImage
                }).compactMap { $0 }
                
                guard let result = faceImages, result.count > 0 else {
                    completion(.notFound)
                    return
                }
                
                completion(.success(result))
            }
            
            do {
                try VNImageRequestHandler(cgImage: self.detectable, options: [:]).perform([req])
            } catch let error {
                completion(.failure(error))
            }
            return
        }else{
            completion(.success(myFaces))
        }
    }
    
    private func cropBarcode(_ completion: @escaping (SmartDetectResult<CGImage>) -> Void) {
        guard #available(iOS 11.0, *) else {
            completion(.failure(NSError(domain: "Error", code: -1000, userInfo: ["OS Error" : "Os is below 11.0"])))
            return
        }
        
        let req = VNDetectBarcodesRequest { request, error in
            guard error == nil else {
                completion(.failure(error!))
                return
            }
            
            let codeImages = request.results?.map({ result -> CGImage? in
                guard let code = result as? VNBarcodeObservation else { completion(.failure(NSError(domain: "Error", code: -1000, userInfo: ["Image Error" : "Image not converted"]))); return nil }
                myCardQrOrBarResult = code.payloadStringValue ?? ""
                let codeImage = self.cropImage(object: code)
                return codeImage
            }).compactMap { $0 }
            
            guard let result = codeImages, result.count > 0 else {
                completion(.notFound)
                return
            }
            
            completion(.success(result))
        }
        
        do {
            try VNImageRequestHandler(cgImage: self.detectable, options: [:]).perform([req])
        } catch let error {
            completion(.failure(error))
        }
    }
    
    private func cropText(_ completion: @escaping (SmartDetectResult<CGImage>) -> Void) {
        guard #available(iOS 11.0, *) else {
            completion(.failure(NSError(domain: "Error", code: -1000, userInfo: ["OS Error" : "Os is below 11.0"])))
            return
        }
        
        let req = VNDetectTextRectanglesRequest { request, error in
            guard error == nil else {
                completion(.failure(error!))
                return
            }
            let textImages = request.results?.map({ result -> CGImage? in
                guard let text = result as? VNTextObservation else { completion(.failure(NSError(domain: "Error", code: -1000, userInfo: ["Image Error" : "Image not converted"]))); return nil}
                let textImage = self.cropImage(object: text)
                return textImage
            }).compactMap { $0 }
            
            guard let result = textImages, result.count > 0 else {
                completion(.notFound)
                return
            }
            completion(.success(result))
        }
        req.reportCharacterBoxes = true
        do {
            try VNImageRequestHandler(cgImage: self.detectable, options: [:]).perform([req])
        } catch let error {
            completion(.failure(error))
        }
    }
    
    private func cropImage(object: VNDetectedObjectObservation) -> CGImage? {
        let width = object.boundingBox.width * CGFloat(self.detectable.width)
        let height = object.boundingBox.height * CGFloat(self.detectable.height)
        let x = object.boundingBox.origin.x * CGFloat(self.detectable.width)
        let y = (1 - object.boundingBox.origin.y) * CGFloat(self.detectable.height) - height
        
        let croppingRect = CGRect(x: x, y: y, width: width, height: height)
        let image = self.detectable.cropping(to: croppingRect)
        return image
    }
}

extension SmartImageDetect where T: UIImage {
    
    func crop(type: DetectionType, completion: @escaping (SmartDetectResult<UIImage>) -> Void) {
        guard #available(iOS 11.0, *) else {
            return
        }
        
        self.detectable.cgImage!.detector.crop(type: type) { result in
            switch result {
            case .success(let cgImages):
                let faces = cgImages.map { cgImage -> UIImage in
                    return UIImage(cgImage: cgImage)
                }
                completion(.success(faces))
            case .notFound:
                completion(.notFound)
            case .failure(let error):
                completion(.failure(error))
            }
        }
        
    }
    
}
