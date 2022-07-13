//
//  CropHelper.swift
//  Smart Doc Recognizer
//
//  Created by Avijit Babu on 08/04/20.
//

import CoreImage
import Vision
import UIKit
import AVFoundation
import TesseractOCR

public struct PassportData{
    public var documentType: String?
    public var countryCode: String?
    public var surnames: String?
    public var givenNames: String?
    public var documentNumber: String?
    public var nationalityCountryCode: String?
    public var birthdate: Date?
    public var sex: String?
    public var expiryDate: Date?
    public var personalNumber: String?
    public var personalNumber2: String?
    public var isDocumentNumberValid: Bool?
    public var isBirthdateValid: Bool?
    public var isExpiryDateValid: Bool?
    public var isPersonalNumberValid: Bool?
    public var allCheckDigitsValid: Bool?
    public var finalImage : UIImage?
    public var passportImage : UIImage?
}

public struct DrivingLicenseData {
    public var finalImage : UIImage?
    public var licenceNo : String?
    public var firstName : String?
    public var lastName : String?
    public var dateOfBirth : Date?
    public var expDate : Date?
    public var faceImage : UIImage?
    public var mobile : [String]?
    public var email : [String]?
    public var websites : [URL]?
}

public struct LicensePlateData{
    public var finalImage : UIImage?
    public var plateImage : UIImage?
    public var plateNumber : String?
}

public struct CreditCardData {
    public var finalImage : UIImage?
    public var cardNumber : String?
    public var name : String?
    public var expiryMonth : String?
    public var expiryYear : String?
}

public struct TaxCardData {
    public var finalImage : UIImage?
    public var cardNumber : String?
    public var firstName : String?
    public var lastName : String?
    public var gender : Gender?
    public var dateOfBirth : Date?
    public var town : String?
    public var province : String?
    public var faceImage : UIImage?
    public var expDate : Date?
    public var mobile : [String]?
    public var email : [String]?
    public var websites : [URL]?
}

public struct IDCardData{
    public var finalImage : UIImage?
    public var documentType: String?
    public var countryCode: String?
    public var name: String?
    public var firstName: String?
    public var lastName: String?
    public var taxCodeCard: String?
    public var documentNumber: String?
    public var nationalityCountryCode: String?
    public var birthdate: Date?
    public var sex: String?
    public var expiryDate: Date?
    public var faceImage : UIImage?
    public var mobile : [String]?
    public var email : [String]?
    public var websites : [URL]?
}

public struct AllSmartDocData  {
    
    public var passportData : PassportData?
    public var drivingLicenseData : DrivingLicenseData?
    public var licensePlateData : LicensePlateData?
    public var taxCardData : TaxCardData?
    public var creditCardData : CreditCardData?
    public var othersIDCardData : IDCardData?
    public var fullText  : String?

}

public struct DataFetcher {
    
    public var finalImage : UIImage?
    public var name : [String]?
    public var firstName : String?
    public var lastName : String?
    public var gender : Gender?
    public var dateOfBirth : Date?
    public var town : String?
    public var province : String?
    public var faceImage : [UIImage]?
    public var textImages : [UIImage]?
    public var qr : [UIImage]?
    public var age : String?
    public var mobile : [String]?
    public var email : [String]?
    public var websites : [URL]?
    public var addresses : [[NSTextCheckingKey: String]]?
    public var idCardNo : String?
    public var anyDates : [Date]?
    public var expDates : [Date]?
    public var previousDates : [Date]?
    public var organizationName : [String]?
    public var places : [String]?
    public var fullText : String?
    public var mrzStr : [String]?
    
}

public class SmartHelper{
    
    public static var defaults = SmartHelper()
    
    //Get all string from QR code if any exists
    func getStrFromQrCode(of : UIImage,completion : @escaping (DataFetcher?)->()){
        let detector:CIDetector=CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh])!
        let ciImage: CIImage = CIImage(image:of)!
        var text=""
        let features = detector.features(in: ciImage)
        for feature in features as! [CIQRCodeFeature] {
            text += feature.messageString ?? ""
        }
        var doc = DataFetcher()
        if text == ""{
            completion(nil)
        }else{
            doc.fullText = text
            doc.addresses = self.extractAddressesIn(text: text)
            doc.anyDates = self.extractDateIn(text: text)
            doc.email = self.extractEmailAddrIn(text: text)
            doc.organizationName = self.extractNamesIn(type: [.organizationName], text: text)
            doc.name = self.extractNamesIn(type: [.personalName], text: text)
            doc.places = self.extractNamesIn(type: [.placeName], text: text)
            doc.mrzStr = self.extractMRZIn(text: text)
            doc.websites = self.extractAllWebsiteLinks(text: text)
            doc.mobile = self.extractMobileNoIn(text: text)
            doc.mobile = self.extractFiscalCodeIn(text: text)
            completion(doc)
        }
        
    }
    //Get all doc text here
    public func getEverythingFromDoc(text : String,type : SmartDocumentType,image : UIImage,completion : @escaping (DataFetcher?)->()){
        let characterSet = Set("+*#$@0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ@\n\t.()-:,/<> ")
        DispatchQueue.main.async {
            let trimmed =  String(text.lazy.filter(characterSet.contains))
            var doc = DataFetcher()
            doc.addresses = self.extractAddressesIn(text: trimmed)
            doc.anyDates = self.extractDateIn(text: trimmed)
            var prev = [Date]()
            var next = [Date]()
            for dt in doc.anyDates ?? [Date](){
                if dt < Date(){
                    prev.append(dt)
                }else{
                    next.append(dt)
                }
            }
            doc.previousDates = prev.sorted(by: {$0 < $1})
            doc.expDates = next.sorted(by: {$0 > $1})
            doc.fullText = trimmed
            doc.finalImage = image
            if type == .tax_Code_Card{
                let fiscalCodeManager = FiscalCodeManager()
                doc.websites = self.extractAllWebsiteLinks(text: trimmed)
                doc.mobile = self.extractMobileNoIn(text: trimmed)
                doc.email = self.extractEmailAddrIn(text: trimmed)
                doc.idCardNo = self.extractTaxCard(from: trimmed)
                let (f,l) = self.extractTaxFirstLastNameInfo(from: trimmed)
                let data = fiscalCodeManager.retriveInformationFrom(fiscalCode: doc.idCardNo ?? "")
                doc.firstName = data?.name
                doc.lastName = data?.surname
                if let fname = f{
                    doc.firstName = fname
                }
                if let lname = l{
                    doc.lastName = lname
                }
                doc.gender = data?.gender
                doc.province = data?.province
                doc.dateOfBirth = data?.date
                doc.town = data?.town
                self.fetchFaceQr(image: image, isFaceNeed: false) { (faces, qrs) in
                    doc.faceImage = faces
                    completion(doc)
                }
            }else if type == .passport{
                self.fetchFaceQr(image: image, isFaceNeed: true) { (faces, qrs) in
                    doc.faceImage = faces
                    doc.mrzStr = self.extractMRZIn(text: text)
                    completion(doc)
                }
            }else if type == .license_Plate{
                self.fetchTextIcludeImages(image: image) { (plates) in
                    guard let tesseract  = G8Tesseract(language: "ocrb_int+mrz+ocr") else {completion(doc); return }
                    tesseract.engineMode = .lstmOnly
                    tesseract.pageSegmentationMode = .autoOnly
                    tesseract.maximumRecognitionTime = 60
                    var full = ""
                    var imgs = [UIImage]()
                    if let plate = plates{
                        for p in plate{
                            tesseract.image = p.fixOrientation()
                            tesseract.recognize()
                            full.append("\n\(tesseract.recognizedText ?? "")")
                            let newString = (tesseract.recognizedText ?? "").replacingOccurrences(of: " ", with: "")
                            let first = newString.first ?? Character("")
                            let last = newString.last ?? Character("")
                            if (first.isUppercase && first.isLetter) && (last.isUppercase && last.isLetter) && (newString.filter { ("0"..."9").contains($0)}.count > 0) && (newString.count >= 5){
                                if doc.idCardNo == nil{
                                    doc.idCardNo = (tesseract.recognizedText ?? "")
                                    imgs.append(p)
                                }
                                return
                            }
                        }
                    }
                    doc.textImages = imgs
                    doc.fullText = full
                    doc.anyDates = self.extractDateIn(text: full)
                    var prev = [Date]()
                    var next = [Date]()
                    for dt in doc.anyDates ?? [Date](){
                        if dt < Date(){
                            prev.append(dt)
                        }else{
                            next.append(dt)
                        }
                    }
                    doc.previousDates = prev.sorted(by: {$0 < $1})
                    doc.expDates = next.sorted(by: {$0 > $1})
                    completion(doc)
                }
            }else if type == .driver_License{
                self.fetchFaceQr(image: image, isFaceNeed: true) { (faces, qr) in
                    doc.faceImage = faces
                    let (fn, ln, id) = self.extractDrivingLicenceData(from: trimmed)
                    doc.firstName = fn
                    doc.lastName = ln
                    doc.idCardNo = id
                    completion(doc)
                }
            }else{
                self.fetchFaceQr(image: image, isFaceNeed: true) { (faces, qrs) in
                    doc.mrzStr = self.extractMRZIn(text: text)
                    doc.websites = self.extractAllWebsiteLinks(text: trimmed)
                    doc.mobile = self.extractMobileNoIn(text: trimmed)
                    doc.email = self.extractEmailAddrIn(text: trimmed)
                    let (a,b) = self.extractTaxFirstLastNameInfo(from: trimmed)
                    doc.firstName = a
                    doc.lastName = b
                    doc.fullText = trimmed
                    doc.idCardNo = self.extractIdCardFromPaper(text: trimmed)
                    self.fetchFaceQr(image: image, isFaceNeed: false) { (faces, qrs) in
                        doc.qr = qrs
                        self.fetchFaceQr(image: image, isFaceNeed: true) { (faces, qrs) in
                            doc.faceImage = faces
                            completion(doc)
                        }
                    }
                }
            }
        }
    }
    
    
    func fetchTextIcludeImages(image : UIImage,completion :@escaping (_ plate : [UIImage]?)->()){
        image.detector.crop(type: .text) { (result) in
            var plates = [UIImage]()
            switch result{
            case .success(let imgs) :
                plates = imgs
                break
            case .notFound:
                break
            case .failure(_):
                break
            }
            completion(plates)
        }
    }
    
    func fetchFaceQr(image: UIImage,isFaceNeed : Bool,completion :@escaping (_ face : [UIImage]?,_ qr : [UIImage]?)->()){
        if isFaceNeed{
            image.detector.crop(type: .face) { (result) in
                var faces = [UIImage]()
                switch result{
                case .success(let imgs) :
                    faces = imgs
                    break
                case .notFound:
                    break
                case .failure(_):
                    break
                }
                completion(faces,nil)
            }
        }else{
            image.detector.crop(type: .barcode) { (result) in
                var qrs = [UIImage]()
                switch result{
                case .success(let imgs) :
                    qrs = imgs
                    break
                case .notFound:
                    break
                case .failure(_):
                    break
                }
                completion(nil,qrs)
            }
        }
    }
    
    //All extractor are here
    func extractDateIn(text: String) -> [Date]? {
        var results = [Date]()
        do {
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
            let matches = detector.matches(in: text, range: NSRange(text.startIndex..., in: text))
            
            for match in matches{
                if match.resultType == .date, let date = match.date {
                    results.append(date)
                }
            }
        } catch {
            print(error)
        }
        return results
    }
    
    func extractAddressesIn(text: String) -> [[NSTextCheckingKey: String]]? {
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.address.rawValue)
        let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        var resultsArray =  [[NSTextCheckingKey: String]]()
        // put matches into array of Strings
        for match in matches {
            if match.resultType == .address,
                let components = match.addressComponents {
                resultsArray.append(components)
            } else {
                print("no components found")
            }
        }
        return resultsArray
    }
    
    func extractTaxCard(from : String)->String?{
        for item in from.components(separatedBy: "\n"){
            for it in item.components(separatedBy: " "){
                if it.trimed.isValidFiscalCode{
                    return it.trimed
                }
            }
        }
        return nil
    }
    
    func extractAllWebsiteLinks(text: String) -> [URL]? {
        var links: [URL] = []
        let types: NSTextCheckingResult.CheckingType = .link
        do {
            let detector = try NSDataDetector(types: types.rawValue)
            let matches = detector.matches(in: text, options: .reportCompletion, range: NSMakeRange(0, text.count))
            for match in matches {
                if let url = match.url{
                    if url.absoluteString.hasPrefix("mailto:") || url.absoluteString.hasPrefix("tel://"){
                        //reject url
                    }else{
                        links.append(url)
                    }
                }
            }
            
        } catch {
            print ("error in findAndOpenURL detector")
        }
        return links
    }
    
    public func extractTaxFirstLastNameInfo(from : String)->(String?,String?){
        var fName : String?
        var lName : String?
        for m in from.components(separatedBy: "\n").filter({!$0.isEmpty}){
            if m.matchFoundWith(array: ["Cognome","Cog","Co","Cognom","Cogno","Cogn","Cogm","Cognme","Cogme"]){
                fName = m.fetchCapitalizeString.first
            }
            if m.matchFoundWith(array: ["Nome","Nom"]){
                lName = m.fetchCapitalizeString.first
            }
        }
        return (fName,lName)
    }
    
    func extractNamesIn(type : [NSLinguisticTag],text: String) -> [String]? {
        var names = [String]()
        let tagger = NSLinguisticTagger(tagSchemes: [.tokenType, .language, .lexicalClass, .nameType, .lemma], options: 0)
        let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        tagger.string = text
        let range = NSRange(location: 0, length: text.utf16.count)
        let tags: [NSLinguisticTag] = type
        tagger.enumerateTags(in: range, unit: .word, scheme: .nameType, options: options) { tag, tokenRange, stop in
            if let tag = tag, tags.contains(tag) {
                for _ in tags{
                    let namestr = (text as NSString).substring(with: tokenRange)
                    names.append(namestr)
                }
            }
        }
        return names
    }
    
    func extractMobileNoIn(text: String) -> [String]? {
        var results = [String]()
        
        do {
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.phoneNumber.rawValue)
            let matches = detector.matches(in: text, range: NSRange(text.startIndex..., in: text))
            
            for match in matches{
                if match.resultType == .phoneNumber, let number = match.phoneNumber {
                    results.append(number)
                }
            }
        } catch {
            print(error)
        }
        
        return results
    }
    
    func extractIdCardFromPaper(text: String) -> String?{
        var id : String?
        for m in text.components(separatedBy: "\n").filter({!$0.isEmpty}){
            let filter1 = m.components(separatedBy: " ").filter({($0.count >= 6 && (($0.isWordHasOnlyNumbers))) || ($0.count == 2 && (($0.isUpperCasedWord)))})
            let filter2 = m.components(separatedBy: " ").filter({($0.count >= 8) && ($0.filter({$0.isNumber}).count >= 6) && ($0.filter({$0.isLetter && $0.isUppercase}).count == 2)})
            if filter1.count == 2{
                id = filter1.joined()
                return id
            }
            if id == nil{
                id = filter2.first
            }
        }
        return id
    }
    
    
    func extractMRZIn(text: String) -> [String]? {
        var results = [String]()
        let mrzString = text.replacingOccurrences(of: " ", with: "")
        let mrzLines = mrzString.components(separatedBy: "\n").filter({ !$0.isEmpty })
        if !mrzLines.isEmpty {
            for line in mrzLines{
                if line.matches("[A-Z0-9<]+") && line.contains("<<") && line.count > 25{
                    results.append(line)
                }
            }
        }
        if results.count == 3{
            for i in 0..<results.count{
                for _ in 0..<results[i].count{
                    if results[i].count > 30{
                        results[i].removeLast()
                    }
                    if results[i].count < 30{
                        results[i].append("<")
                    }
                }
            }
        }
        return results
    }
    
    func extractEmailAddrIn(text: String) -> [String]? {
        var results = [String]()
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
        let nsText = text as NSString
        do {
            let regExp = try NSRegularExpression(pattern: emailRegex, options: NSRegularExpression.Options.caseInsensitive)
            let range = NSMakeRange(0, text.count)
            let matches = regExp.matches(in: text, options: .reportProgress, range: range)
            
            for match in matches {
                let matchRange = match.range
                results.append(nsText.substring(with: matchRange))
            }
            
        } catch _ {
        }
        
        return results
    }
    
    func extractDrivingLicenceData(from : String)->(String?,String?,String?){
        var fname : String?
        var lname : String?
        var id : String?
        let arr = from.split(separator: "\n")
        for n in arr{
            if fname?.count ?? 0 == 0{
                if n.first == "1"{
                    if let fn = n.components(separatedBy: " ").filter({$0.count > 2}).last?.description.trimed,fn.count > 2{
                        fname = fn
                    }else if let fn = n.components(separatedBy: ".").filter({$0.count > 2}).last?.description.trimed,fn.count > 2{
                        fname = fn
                    }else{
                        fname = n.replacingOccurrences(of: "1", with: "")
                    }
                }else if n.contains("1."){
                    fname = n.components(separatedBy: "1.").last?.trimed
                }
            }
            if lname?.count ?? 0 == 0{
                if n.first == "2"{
                    if let ln = n.components(separatedBy: " ").filter({$0.count > 2}).last?.description.trimed,ln.count > 2{
                        lname = ln
                    }else if let ln = n.components(separatedBy: ".").filter({$0.count > 2}).last?.description.trimed,ln.count > 2{
                        lname = ln
                    }else{
                        lname = n.replacingOccurrences(of: "2", with: "")
                    }
                }else if n.contains("2."){
                    lname = n.components(separatedBy: "2.").last?.trimed
                }
            }
            if id?.count ?? 0 == 0{
                if n.first == "5"{
                    if let did = n.components(separatedBy: " ").filter({$0.count > 2}).last?.description.trimed,did.count > 2{
                        id = did
                    }else if let did = n.components(separatedBy: ".").filter({$0.count > 2}).last?.description.trimed,did.count > 2{
                        id = did
                    }else{
                        id = n.replacingOccurrences(of: "5", with: "")
                    }
                }else if n.contains("5."){
                    id = n.components(separatedBy: "5.").last?.trimed
                }
            }
            if id == nil{
                id = n.components(separatedBy: " ").filter({$0.count == 10 && ($0.first?.isUppercase ?? true) && ($0.last?.isUppercase ?? true) && (($0.filter { ("0"..."9").contains($0)}.count > 0))}).first
            }
        }
        return (fname,lname,id)
    }
    
    func extractFiscalCodeIn(text: String) -> [String]? {
        var results = [String]()
        let fiscalRegex = "^([A-Za-z]{6}[0-9lmnpqrstuvLMNPQRSTUV]{2}[abcdehlmprstABCDEHLMPRST]{1}[0-9lmnpqrstuvLMNPQRSTUV]{2}[A-Za-z]{1}[0-9lmnpqrstuvLMNPQRSTUV]{3}[A-Za-z]{1})|([0-9]{11})$"
        let nsText = text as NSString
        do {
            let regExp = try NSRegularExpression(pattern: fiscalRegex, options: NSRegularExpression.Options.caseInsensitive)
            let range = NSMakeRange(0, text.count)
            let matches = regExp.matches(in: text, options: .reportProgress, range: range)
            
            for match in matches {
                let matchRange = match.range
                results.append(nsText.substring(with: matchRange))
            }
            
        } catch _ {
        }
        
        return results
    }
    
    //Take camera permission
    func canGetPermission(from : UIViewController ,_ completion : ((Bool)->())? = nil){
        DispatchQueue.main.async {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            switch status {
            case .authorized:
                completion?(true)
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                        completion?(true)
                    }else{
                        completion?(false)
                    }
                }
            case .denied :
                from.showTwoButtonAlertWithRightAction(title: "Not Granted", buttonTitleLeft: "Re-check", buttonTitleRight: "Open Settings", message: "You not provide camera record permission to us.Therefore, we can't process") {
                    // Take the user to Settings app to possibly change permission.
                    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        if #available(iOS 10.0, *) {
                            UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                                // Finished opening URL
                            })
                        } else {
                            // Fallback on earlier versions
                            UIApplication.shared.openURL(settingsUrl)
                        }
                    }
                }
                
            default:
                completion?(false)
            }
        }
        
    }
    //make image black and white
    func pureBlackAndWhiteImage(_ inputImage: UIImage) -> UIImage? {
        
        guard let inputCGImage = inputImage.cgImage, let context = getImageContext(for: inputCGImage), let data = context.data else { return nil }
        
        let white = RGBA32(red: 255, green: 255, blue: 255, alpha: 255)
        let black = RGBA32(red: 0, green: 0, blue: 0, alpha: 255)
        
        let width = Int(inputCGImage.width)
        let height = Int(inputCGImage.height)
        let pixelBuffer = data.bindMemory(to: RGBA32.self, capacity: width * height)
        
        for x in 0 ..< height {
            for y in 0 ..< width {
                let offset = x * width + y
                if pixelBuffer[offset].red > 0 || pixelBuffer[offset].green > 0 || pixelBuffer[offset].blue > 0 {
                    pixelBuffer[offset] = black
                } else {
                    pixelBuffer[offset] = white
                }
            }
        }
        
        let outputCGImage = context.makeImage()
        let outputImage = UIImage(cgImage: outputCGImage!, scale: inputImage.scale, orientation: inputImage.imageOrientation)
        
        return outputImage
    }
    //Get image context by CoreImage
    func getImageContext(for inputCGImage: CGImage) ->CGContext? {
        
        let colorSpace       = CGColorSpaceCreateDeviceRGB()
        let width            = inputCGImage.width
        let height           = inputCGImage.height
        let bytesPerPixel    = 4
        let bitsPerComponent = 8
        let bytesPerRow      = bytesPerPixel * width
        let bitmapInfo       = RGBA32.bitmapInfo
        
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else {
            print("unable to create context")
            return nil
        }
        
        context.setBlendMode(.copy)
        context.draw(inputCGImage, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        
        return context
    }
    
    struct RGBA32: Equatable {
        var color: UInt32
        
        var red: UInt8 {
            return UInt8((color >> 24) & 255)
        }
        
        var green: UInt8 {
            return UInt8((color >> 16) & 255)
        }
        
        var blue: UInt8 {
            return UInt8((color >> 8) & 255)
        }
        
        var alpha: UInt8 {
            return UInt8((color >> 0) & 255)
        }
        
        init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
            color = (UInt32(red) << 24) | (UInt32(green) << 16) | (UInt32(blue) << 8) | (UInt32(alpha) << 0)
        }
        
        static let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
    }
}

//Its provide result after crop
public struct CropHelper {

	public typealias Completion = (SmartDocResult) -> Void

	static func crop(buffer: CVPixelBuffer, quad: RectangularSwap, completion: @escaping Completion) {
		DispatchQueue.global(qos: .userInteractive).async {
			let ciImage = CIImage(cvPixelBuffer: buffer)
			let context = CIContext()

			guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
			let image = UIImage(cgImage: cgImage, scale: 1, orientation: .right).fixOrientation()

			let size = ciImage.extent.size
			let width = Int(size.width)
			let height = Int(size.height)

			let points: [CGPoint]
			if #available(iOS 11.0, *) {
				points = quad.points.map { VNImagePointForNormalizedPoint($0, width, height) }
			} else {
				points = quad.points.map { $0.scaledAbsolute(size: size) }
			}
			let converted = points.map { $0.cartesian(height: size.height) }

			let result: SmartDocResult
			if let quad = RectangularSwap(clockwise: converted), let cropped = applyPersperpectiveCorrection(ciImage: ciImage, quad: quad) {
				result = SmartDocResult(original: image, cropped: cropped, quad: quad)
			} else {
				result = SmartDocResult(original: image, cropped: nil, quad: nil)
			}

			DispatchQueue.main.async {
				completion(result)
			}
		}
	}
    //Set image swap when if not semetric on screen
	private static func applyPersperpectiveCorrection(ciImage: CIImage, quad: RectangularSwap) -> UIImage? {
		guard let filter = CIFilter(name: "CIPerspectiveCorrection") else { return nil }
		let context = CIContext(options: nil)

		filter.setValue(CIVector(cgPoint: quad.topLeft), forKey: "inputTopLeft")
		filter.setValue(CIVector(cgPoint: quad.topRight), forKey: "inputTopRight")
		filter.setValue(CIVector(cgPoint: quad.bottomLeft), forKey: "inputBottomLeft")
		filter.setValue(CIVector(cgPoint: quad.bottomRight), forKey: "inputBottomRight")
		filter.setValue(ciImage, forKey: kCIInputImageKey)

		guard let correctedImage = filter.outputImage, let cgImage = context.createCGImage(correctedImage, from: correctedImage.extent) else { return nil }
		return UIImage(cgImage: cgImage, scale: 1, orientation: .right)
	}

}


public protocol SequenceRectangleDetector: class {
    
    typealias Update = (Observation) -> Void
    
    var update: Update? { get set }
    func detect(on pixelBuffer: CVPixelBuffer)
    
}

public protocol ImageRectangleDetector: class {
    
    typealias Completion = (RectangularSwap?) -> Void
    func detect(image: UIImage, completion: @escaping Completion)
    
}


public final class CIImageRectangleDetector: ImageRectangleDetector {
    
    public func detect(image: UIImage, completion: @escaping Completion) {
        DispatchQueue.global().async {
            guard let ciImage = CIImage(image: image) else { return }
            
            guard let detector = CIDetector(ofType: CIDetectorTypeRectangle, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]) else { return }
            
            let results = detector.features(in: ciImage)
            let sortedBySize = results.sorted { $0.bounds.area > $1.bounds.area }
            
            if let feature = sortedBySize.first as? CIRectangleFeature {
                let size = ciImage.extent.size
                let points = [feature.topLeft, feature.topRight, feature.bottomRight, feature.bottomLeft]
                let normalized = points.map { $0.scaledRelative(size: size) }
                
                let quad = RectangularSwap(clockwise: normalized)
                
                DispatchQueue.main.async {
                    completion(quad)
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
}

public final class NoSequenceRectangleDetector: SequenceRectangleDetector {
    
    public var update: SequenceRectangleDetector.Update?
    public func detect(on pixelBuffer: CVPixelBuffer) { }
    
}


@available(iOS 11.0, *)
public final class VisionSequenceRectangleDetector: SequenceRectangleDetector {
    private var data: [NSObject: CVPixelBuffer] = [:]
    public var update: Update?
    
    private lazy var visionRequestHandler = VNSequenceRequestHandler()
    
    public func detect(on pixelBuffer: CVPixelBuffer) {
        let request = VNDetectRectanglesRequest(completionHandler: handle)
        request.minimumConfidence = 0.5
        request.maximumObservations = 4
        request.minimumSize = 0.3
        request.minimumAspectRatio = 0.2
        request.maximumAspectRatio = 1
        request.quadratureTolerance = 45
        request.preferBackgroundProcessing = true
        execute(request: request, buffer: pixelBuffer)
    }
    
    private func execute(request: VNRequest, buffer: CVPixelBuffer) {
        do {
            data[request] = buffer
            try visionRequestHandler.perform([request], on: buffer)
        } catch {
            complete(buffer: buffer)
        }
    }
    
    private func handle(request: VNRequest, error: Error?) {
        guard let buffer = data.removeValue(forKey: request) else { return }
        guard let observations = request.results as? [VNRectangleObservation] else { return }
        let sorted = observations.sorted { $0.confidence > $1.confidence }
        if let result = sorted.first {
            complete(observation: result, buffer: buffer)
        } else {
            complete(buffer: buffer)
        }
    }
    
    private func complete(observation: VNRectangleObservation? = nil, buffer: CVPixelBuffer) {
        let result: Observation
        if let observation = observation {
            result = Observation(quad: RectangularSwap(obvservation: observation), buffer: buffer)
        } else {
            result = Observation(quad: nil, buffer: buffer)
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.update?(result)
        }
    }
    
}


@available(iOS 11.0, *)
public final class VisionImageRectangleDetector: ImageRectangleDetector {
    
    private var completionHandler: Completion?
    
    public func detect(image: UIImage, completion: @escaping Completion) {
        guard let cgImage = image.cgImage else { return }
        
        let request = VNDetectRectanglesRequest(completionHandler: handleRequest)
        request.minimumAspectRatio = 0
        request.quadratureTolerance = 45
        request.preferBackgroundProcessing = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            completionHandler = completion
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    @available(iOS 11.0, *)
    private func handleRequest(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNRectangleObservation] else { return }
        let sortedByConfidence = observations.sorted { $0.confidence > $1.confidence }
        
        if let observation = sortedByConfidence.first {
            let quad = RectangularSwap(obvservation: observation)
            
            DispatchQueue.main.async { [weak self] in
                self?.completionHandler?(quad)
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.completionHandler?(nil)
            }
        }
    }
    
}
