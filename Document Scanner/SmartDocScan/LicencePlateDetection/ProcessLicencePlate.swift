//
//  ProcessLicencePlate.swift
//  Document Scanner
//
//  Created by Avijit Babu on 22/05/20.
//  Copyright © 2020 Avijit Babu. All rights reserved.
//

import Foundation
import UIKit
import CoreImage
import Vision
import TesseractOCR


@available(iOS 13.0, *)
public class ProcessLicencePlateLatest : NSObject {
    
    public var getText : ((AllSmartDocData?,Error?)->())?
    private var image = UIImage()
    private var objectBounds = CGRect()
    
    required init(_ image : UIImage) {
        super.init()
        self.image = image
    }
    
    
    func process(){
        if let cgImg = image.cgImage{
            textRecognition(image: cgImg)
        }else{
            getText?(nil, NSError(domain: "Error", code: -1009, userInfo: ["err" : "Image not converted"]))
        }
    }
    
    func textRecognition(image:CGImage){
        // 1. Request
        let textRecognitionRequest = VNRecognizeTextRequest(completionHandler: self.handleDetectedText)
        textRecognitionRequest.recognitionLevel = .accurate
        textRecognitionRequest.recognitionLanguages = ["en_US"]
        textRecognitionRequest.usesLanguageCorrection = false
        textRecognitionRequest.customWords = ["HR26DK8337", "TN09EF8790", "MH12FE8999", "TS07EW9812"]
        
        // 2. Request Handler
        let textRequest = [textRecognitionRequest]
        let imageRequestHandler = VNImageRequestHandler(cgImage: image, orientation: .up, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // 3. Perform request
                try imageRequestHandler.perform(textRequest)
            } catch let error {
                self.getText?(nil, error)
            }
        }
        
    }
    
    func handleDetectedText(request: VNRequest?, error:Error?){
        if let error = error {
            getText?(nil, error)
            return 
        }
        guard let results = request?.results, results.count > 0 else {
            getText?(nil, NSError(domain: "Error", code: -1008, userInfo: ["err" : "Image has no text"]))
            return
        }
        for result in results {
            if let observation = result as? VNRecognizedTextObservation {
                for text in observation.topCandidates(1){
                    DispatchQueue.main.async {
                        do {
                            var t:CGAffineTransform = CGAffineTransform.identity;
                            t = t.scaledBy( x: self.image.size.width, y: -self.image.size.height);
                            t = t.translatedBy(x: 0, y: -1 );
                            self.objectBounds = observation.boundingBox.applying(t)
                            let newString = text.string.replacingOccurrences(of: " ", with: "")
                            let first = newString.first ?? Character("")
                            let last = newString.last ?? Character("")
                            if (first.isUppercase && first.isLetter) && (last.isUppercase && last.isLetter) && (newString.filter { ("0"..."9").contains($0)}.count > 0) && (newString.count >= 5){
                                let imageWithBoundingBox =  self.drawRectangleOnImage(image: self.image, x: Double(self.objectBounds.minX), y: Double(self.objectBounds.minY), width: Double(self.objectBounds.width), height: Double(self.objectBounds.height))
                                let ract = CGRect(x: Double(self.objectBounds.minX), y: Double(self.objectBounds.minY), width: Double(self.objectBounds.width), height: Double(self.objectBounds.height))
                                var myType = AllSmartDocData()
                                var licenceData = LicensePlateData()
                                licenceData.finalImage = imageWithBoundingBox
                                licenceData.plateImage = self.image.crop(rect: ract)
                                licenceData.plateNumber = text.string
                                myType.fullText = newString
                                myType.licensePlateData = licenceData
                                self.getText?(myType,nil)
                            }else{
                                self.getText?(nil, NSError(domain: "Error", code: -1007, userInfo: ["err" : "Image has proper licence plate"]))
                            }
                        }
                    }
                }
            }
        }
    }
    
    func drawRectangleOnImage(image: UIImage, x:Double, y:Double, width:Double, height:Double) -> UIImage{
        let imageSize = image.size
        let scale:CGFloat = 0
        UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)
        let context = UIGraphicsGetCurrentContext()
        image.draw(at: CGPoint.zero)
        let rectangelTodraw = CGRect(x:x, y:y, width:width, height:height)
        
        context?.setStrokeColor(UIColor.systemBlue.cgColor)
        context?.setLineWidth(5.0)
        context?.addRect(rectangelTodraw)
        context?.drawPath(using: .stroke)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
}
