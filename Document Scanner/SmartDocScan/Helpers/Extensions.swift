//
//  ExtraFunctionality.swift
//  Smart Doc Recognizer
//
//  Created by Avijit Babu on 08/04/20.
//

import Foundation
import UIKit


public extension UIViewController {
    
    //show alert with Single Button action
    func showSingleButtonAlertWithAction (title:String,buttonTitle:String,message:String,isblurBack :Bool = false,completionHandler:@escaping () -> ()) {
        let blurEffect = UIBlurEffect(style: .light)
        let blurVisualEffectView = UIVisualEffectView(effect: blurEffect)
        blurVisualEffectView.frame = view.bounds
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.0) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: buttonTitle, style: UIAlertAction.Style.default, handler: { action in
                if isblurBack{
                    blurVisualEffectView.removeFromSuperview()
                }
                completionHandler()
            }))
            if isblurBack{
                self.view.addSubview(blurVisualEffectView)
            }
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    //show alert with right action button
    func showTwoButtonAlertWithRightAction (title:String,buttonTitleLeft:String,buttonTitleRight:String,message: String,completionHandler:@escaping () -> ()) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: buttonTitleLeft, style: UIAlertAction.Style.default, handler: nil))
        alert.addAction(UIAlertAction(title: buttonTitleRight, style: UIAlertAction.Style.default, handler: { action in
            completionHandler()
        }))
        self.present(alert, animated: true, completion: nil)
    }
}

extension UIView {
    
    /// Create image snapshot of view.
    ///
    /// - Parameters:
    ///   - rect: The coordinates (in the view's own coordinate space) to be captured. If omitted, the entire `bounds` will be captured.
    ///   - afterScreenUpdates: A Boolean value that indicates whether the snapshot should be rendered after recent changes have been incorporated. Specify the value false if you want to render a snapshot in the view hierarchy’s current state, which might not include recent changes. Defaults to `true`.
    ///
    /// - Returns: The `UIImage` snapshot.
    
    func snapshot(of rect: CGRect? = nil, afterScreenUpdates: Bool = true) -> UIImage {
        return UIGraphicsImageRenderer(bounds: rect ?? bounds).image { _ in
            drawHierarchy(in: bounds, afterScreenUpdates: afterScreenUpdates)
        }
    }
}

public extension UIImage {
    
    //Conver image to a readable image like document
    func getScannedImage() -> UIImage? {
        
        let openGLContext = EAGLContext(api: .openGLES2)
        let context = CIContext(eaglContext: openGLContext!)
        
        let filter = CIFilter(name: "CIColorControls")
        let coreImage = CIImage(image: self)
        
        filter?.setValue(coreImage, forKey: kCIInputImageKey)
        //Key value are changable according to your need.
        filter?.setValue(7, forKey: kCIInputContrastKey)
        filter?.setValue(1, forKey: kCIInputSaturationKey)
        filter?.setValue(1.2, forKey: kCIInputBrightnessKey)
        
        if let outputImage = filter?.value(forKey: kCIOutputImageKey) as? CIImage {
            let output = context.createCGImage(outputImage, from: outputImage.extent)
            return UIImage(cgImage: output!)
        }
        return nil
    }
    
    var noir: UIImage? {
        let context = CIContext(options: nil)
        guard let currentFilter = CIFilter(name: "CIPhotoEffectNoir") else { return nil }
        currentFilter.setValue(CIImage(image: self), forKey: kCIInputImageKey)
        if let output = currentFilter.outputImage,
            let cgImage = context.createCGImage(output, from: output.extent) {
            return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
        }
        return nil
    }
    
    func fixOrientation(orientation: UIImage.Orientation? = nil) -> UIImage {
        guard orientation == nil && imageOrientation != .up else { return self }
        
        var transform = CGAffineTransform.identity
        let orientation = orientation ?? imageOrientation
        
        switch orientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: CGFloat.pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: CGFloat.pi / 2)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: -(CGFloat.pi / 2))
        default:
            break
        }
        
        switch orientation {
        case .upMirrored, .downMirrored:
            transform.translatedBy(x: size.width, y: 0)
            transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform.translatedBy(x: size.height, y: 0)
            transform.scaledBy(x: -1, y: 1)
        default:
            break
        }
        
        guard let bitsPerComponent = self.cgImage?.bitsPerComponent, let colorSpace = self.cgImage?.colorSpace, let ctx: CGContext = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: bitsPerComponent, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return self }
        ctx.concatenate(transform)
        
        guard let cgImage = self.cgImage else { return self }
        switch orientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            break
        }
        
        guard let image: CGImage = ctx.makeImage() else { return self }
        return UIImage(cgImage: image)
    }
    
}


extension CGPoint {
    
    public func cartesian(height: CGFloat) -> CGPoint {
        return CGPoint(x: x, y: height - y)
    }
    
    public func scaledRelative(size: CGSize) -> CGPoint {
        return CGPoint(x: x / size.width, y: y / size.height)
    }
    
    public func scaledAbsolute(size: CGSize) -> CGPoint {
        return CGPoint(x: x * size.width, y: y * size.height)
    }
    
    func isInRange(other: CGPoint, theshold: CGFloat) -> Bool {
        return x - other.x < theshold && y - other.y < theshold
    }
    
    func multiply(value: CGFloat) -> CGPoint {
        return CGPoint(x: x * value, y: y * value)
    }
    
    func divide(value: CGFloat) -> CGPoint {
        return CGPoint(x: x / value, y: y / value)
    }
    
    public static func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
}


extension CGRect {
    
    public var area: CGFloat {
        return width * height
    }
    
}


public extension Array where Element == CGPoint {
    
    var quadPath: UIBezierPath {
        let path = UIBezierPath()
        
        guard count == 4 else { return path }
        path.move(to: self[0])
        
        for i in 1 ..< 4 {
            path.addLine(to: self[i])
        }
        path.close()
        
        return path
    }
    
}

// MARK: - UIImage extension
extension UIImage {
    func scaledImage(_ maxDimension: CGFloat) -> UIImage? {
        var scaledSize = CGSize(width: maxDimension, height: maxDimension)
        
        if size.width > size.height {
            scaledSize.height = size.height / size.width * scaledSize.width
        } else {
            scaledSize.width = size.width / size.height * scaledSize.height
        }
        UIGraphicsBeginImageContext(scaledSize)
        draw(in: CGRect(origin: .zero, size: scaledSize))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
    
}



extension Array {
    func shifted(by shiftAmount: Int) -> Array<Element> {
        guard self.count > 0, (shiftAmount % self.count) != 0 else { return self }
        let moduloShiftAmount = shiftAmount % self.count
        
        let negativeShift = shiftAmount < 0
        let effectiveShiftAmount = negativeShift ? moduloShiftAmount + self.count : moduloShiftAmount
        let shift: (Int) -> Int = { return $0 + effectiveShiftAmount >= self.count ? $0 + effectiveShiftAmount - self.count : $0 + effectiveShiftAmount }
        
        return self.enumerated().sorted(by: { shift($0.offset) < shift($1.offset) }).map { $0.element }
    }
}


extension CGPoint {
    func cartesian(for size: CGSize) -> CGPoint {
        return CGPoint(x: x, y: size.height - y)
    }
    static func cross(a: CGPoint, b: CGPoint) -> CGFloat {
        return a.x * b.y - a.y * b.x
    }
    func normalized(size: CGSize) -> CGPoint {
        return CGPoint(x: max(min(x, size.width), 0), y: max(min(y, size.height), 0))
    }
}


extension UIView {
    var globalPoint :CGPoint? {
        return self.superview?.convert(self.frame.origin, to: nil)
    }
    var globalFrame :CGRect? {
        return self.superview?.convert(self.frame, to: nil)
    }
}


public extension String {
    /**
        Match string with regex
     */
    func matches(_ regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil
    }
    
    var trimed : String{
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func matchFoundWith(array : [String])-> Bool{
        let mapArr = array.map({self.contains($0)})
        if mapArr.contains(true){
            return true
        }else{
            return false
        }
    }
    
    var fetchCapitalizeString : [String]{
        var results = [String]()
        for line in self.components(separatedBy: " "){
            if line.isUpperCasedWord && line.count > 2{
                results.append(line)
            }
        }
        return results
    }
    
    var isUpperCasedWord : Bool{
        let a = self.filter({$0.isLetter && $0.isUppercase})
        if a.count != self.count{
            return false
        }
        for i in self{
            if i.isLowercase{
                return false
            }
        }
        return true
    }
    
    var isWordHasOnlyNumbers : Bool{
        let a = self.filter({$0.isNumber})
        if a.count != self.count{
            return false
        }else{
            return true
        }
    }
    
    func fetchMatchedRegexString(regex : String) -> [String]{
        var results = [String]()
        for line in self.components(separatedBy: " "){
            if line.matches(regex){
                results.append(line)
            }
        }
        return results
    }
}


public extension UIImage {
    
    func crop( rect: CGRect) -> UIImage {
        var rect = rect
        rect.origin.x*=self.scale
        rect.origin.y*=self.scale
        rect.size.width*=self.scale
        rect.size.height*=self.scale
        
        let imageRef = self.cgImage!.cropping(to: rect)
        let image = UIImage(cgImage: imageRef!, scale: self.scale, orientation: self.imageOrientation)
        return image
    }
    
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!
        
        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        // Draw the image at its center
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}

