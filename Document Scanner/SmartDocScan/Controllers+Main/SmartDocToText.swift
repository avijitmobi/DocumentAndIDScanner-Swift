//
//  ProcessDataTessract.swift
//  Smart Doc Recognizer
//
//  Created by Avijit Babu on 08/04/20.
//

import Foundation
import UIKit
import Vision
import CoreML
import TesseractOCR

//This is for 2 pages data saved
public var otherData = IDCardData()


public var myCardQrOrBarResult : String = ""
public class MyProcess{
    //Convert result into my own model
    public static func passportResult(from : MyMRZResult?,finalImage : UIImage?, passportImg : UIImage?)->PassportData{
        var pd = PassportData()
        pd.documentType = from?.documentType
        pd.countryCode = from?.countryCode
        pd.surnames = from?.surnames
        pd.givenNames = from?.givenNames
        pd.documentNumber = from?.documentNumber
        pd.nationalityCountryCode = from?.nationalityCountryCode
        pd.birthdate = from?.birthdate
        pd.sex = from?.sex
        pd.expiryDate = from?.expiryDate
        pd.personalNumber = from?.personalNumber
        pd.personalNumber2 = from?.personalNumber2
        pd.isDocumentNumberValid = from?.isDocumentNumberValid
        pd.isBirthdateValid = from?.isBirthdateValid
        pd.isExpiryDateValid = from?.isExpiryDateValid
        pd.isPersonalNumberValid = from?.isPersonalNumberValid
        pd.allCheckDigitsValid = from?.allCheckDigitsValid
        pd.finalImage = finalImage
        pd.passportImage = passportImg
        return pd
    }
    
    
    public static func processPassport(image : UIImage,com : @escaping(AllSmartDocData?,Error?)->()){
        guard let tesseract  = G8Tesseract(language: "mrz+orcb_int") else {com(nil,NSError(domain: "Error", code: -1003, userInfo: ["err" : "Image not converted"])); return }
        let scaledImage = (image.scaledImage(2000) ?? image) |> adjustColors |> convertToGrayscale
        tesseract.engineMode = .lstmOnly
        tesseract.pageSegmentationMode = .auto
        tesseract.image = scaledImage
        tesseract.maximumRecognitionTime = 60
        tesseract.recognize()
        DispatchQueue.main.async{
            SmartHelper.defaults.getEverythingFromDoc(text: tesseract.recognizedText, type: .passport, image: image.scaledImage(1000) ?? image) { (type) in
                var myType = AllSmartDocData()
                let mrzParser = MyMRZParser(ocrCorrection: true)
                let mrz = mrzParser.parse(mrzLines: type?.mrzStr ?? [String]())
                myType.passportData = MyProcess.passportResult(from: mrz, finalImage: image, passportImg: type?.faceImage?.first)
                com(myType,nil)
            }
        }
    }
    
    public static func processLicencePlate(image : UIImage,com : @escaping(AllSmartDocData?,Error?)->()){
        DispatchQueue.main.async{
            SmartHelper.defaults.getEverythingFromDoc(text: "", type: .license_Plate, image: image.scaledImage(2500) ?? image) { (type) in
                var myType = AllSmartDocData()
                var licenceData = LicensePlateData()
                licenceData.finalImage = image
                licenceData.plateImage = type?.textImages?.first
                licenceData.plateNumber = type?.idCardNo
                myType.fullText = type?.fullText
                myType.licensePlateData = licenceData
                com(myType,nil)
            }
        }
    }
    
    public static func processTaxCard(image : UIImage,com : @escaping(AllSmartDocData?,Error?)->()){
        guard let tesseract  = G8Tesseract(language: "ocrb_int+ita+eng") else {com(nil, NSError(domain: "Error", code: -1003, userInfo: ["err" : "Image not converted"])); return }
        let scaledImage = (image.scaledImage(2300) ?? image) |> adjustColors |> convertToGrayscale
        tesseract.engineMode = .lstmOnly
        tesseract.pageSegmentationMode = .autoOnly
        tesseract.image = scaledImage
        tesseract.maximumRecognitionTime = 60
        tesseract.recognize()
        DispatchQueue.main.async{
            SmartHelper.defaults.getEverythingFromDoc(text: tesseract.recognizedText, type: .tax_Code_Card, image: image.scaledImage(1500) ?? image) { (type) in
                var myType = AllSmartDocData()
                var tax = TaxCardData()
                tax.cardNumber = type?.idCardNo
                tax.email = type?.email
                tax.mobile = type?.mobile
                tax.websites = type?.websites
                tax.expDate = type?.expDates?.first
                tax.dateOfBirth = type?.dateOfBirth
                tax.firstName = type?.firstName
                tax.lastName = type?.lastName
                tax.town = type?.town
                tax.gender = type?.gender
                tax.province = type?.province
                tax.faceImage = type?.faceImage?.first
                tax.finalImage = image
                myType.fullText = type?.fullText
                myType.taxCardData = tax
                com(myType,nil)
            }
        }
    }
    
    public static func processDrivingLicence(image : UIImage,com : @escaping(AllSmartDocData?,Error?)->()){
        guard let tesseract  = G8Tesseract(language: "ita+eng+ocrb_int+mrz") else {com(nil, NSError(domain: "Error", code: -1003, userInfo: ["err" : "Image not converted"])); return }
        let scaledImage = (image.scaledImage(2300) ?? image)
        tesseract.engineMode = .lstmOnly
        tesseract.pageSegmentationMode = .autoOnly
        tesseract.image = scaledImage
        tesseract.maximumRecognitionTime = 60
        tesseract.recognize()
        DispatchQueue.main.async{
            SmartHelper.defaults.getEverythingFromDoc(text: tesseract.recognizedText, type: .driver_License, image: image.scaledImage(1500) ?? image) { (type) in
                var myType = AllSmartDocData()
                myType.fullText = type?.fullText
                var dr = DrivingLicenseData()
                dr.email = type?.email
                dr.firstName = type?.firstName
                dr.lastName = type?.lastName
                dr.licenceNo = type?.idCardNo
                dr.faceImage = type?.faceImage?.first
                dr.mobile = type?.mobile
                dr.websites = type?.websites
                dr.finalImage = type?.finalImage
                dr.dateOfBirth = type?.previousDates?.first
                dr.expDate = type?.expDates?.last ?? type?.previousDates?.last
                myType.drivingLicenseData = dr
                com(myType,nil)
            }
        }
    }
    
    public static func processOtherCard(image : UIImage,com : @escaping(AllSmartDocData?,Error?)->()){
        guard let tesseract  = G8Tesseract(language: "mrz+orcb_int+ita+eng") else {com(nil, NSError(domain: "Error", code: -1003, userInfo: ["err" : "Image not converted"])); return }
        let scaledImage = (image.scaledImage(2000) ?? image)
        tesseract.engineMode = .lstmOnly
        tesseract.pageSegmentationMode = .autoOnly
        tesseract.image = scaledImage
        tesseract.maximumRecognitionTime = 60
        print(tesseract.progress)
        tesseract.recognize()
        DispatchQueue.main.async{
            SmartHelper.defaults.getEverythingFromDoc(text: tesseract.recognizedText, type: .others_Id, image: image.scaledImage(1000) ?? image) { (type) in
                otherCardProcess += 1
                var myType = AllSmartDocData()
                myType.fullText = type?.fullText
                let mrzParser = MyMRZParser(ocrCorrection: true)
                otherData.taxCodeCard = myCardQrOrBarResult
                if otherData.finalImage == nil{
                    otherData.finalImage = type?.finalImage
                }
                if otherData.faceImage == nil{
                  otherData.faceImage = type?.faceImage?.first
                }
                if type?.mrzStr?.count ?? 0 > 1{
                    let mrz = mrzParser.parse(mrzLines: type?.mrzStr ?? [String]())
                    otherData.documentType = mrz?.documentType
                    otherData.countryCode = mrz?.countryCode
                    otherData.name = (mrz?.givenNames ?? "") + " " + (mrz?.surnames ?? "")
                    otherData.firstName = mrz?.givenNames
                    otherData.lastName = mrz?.surnames
                    otherData.documentNumber = mrz?.documentNumber
                    otherData.nationalityCountryCode = mrz?.nationalityCountryCode
                    otherData.birthdate = mrz?.birthdate
                    otherData.sex = mrz?.sex
                    otherData.expiryDate = mrz?.expiryDate
                }else{
                    otherData.email = type?.email
                    otherData.name = type?.name?.first
                    otherData.firstName = type?.firstName
                    otherData.lastName = type?.lastName
                    otherData.documentNumber = type?.idCardNo
                    otherData.mobile = type?.mobile
                    otherData.websites = type?.websites
                    otherData.birthdate = type?.previousDates?.first
                    otherData.expiryDate = type?.expDates?.last
                }
                myType.othersIDCardData = otherData
                com(myType,nil)
            }
        }
    }
    
}

public class ProcessDataTessract : NSObject {
    
    public var getText : ((AllSmartDocData?,Error?)->())?
    private var image = UIImage()
    private var docType : SmartDocumentType = .others_Id
    
    
    required init(_ image : UIImage,type : SmartDocumentType) {
        super.init()
        self.image = image
        self.docType = type
    }
    
    
    func process(){
        if docType == .passport{
            MyProcess.processPassport(image: image) { (data,err)  in
                self.getText?(data,err)
            }
        }else if docType == .license_Plate{
            if #available(iOS 13.0, *){
                let alpr = ProcessLicencePlateLatest(image)
                alpr.process()
                alpr.getText = { data,err in
                    self.getText?(data,err)
                }
            }else{
                MyProcess.processLicencePlate(image: image) { (data,err) in
                    self.getText?(data,err)
                }
            }
        }else if docType == .tax_Code_Card{
            MyProcess.processTaxCard(image: image) { (data, err) in
                self.getText?(data,err)
            }
        }else if docType == .driver_License{
            MyProcess.processDrivingLicence(image: image) { (data, err) in
                self.getText?(data,err)
            }
        }else{
            MyProcess.processOtherCard(image: image) { (data,err) in
                self.getText?(data,err)
            }
        }
        
    }
    
}

