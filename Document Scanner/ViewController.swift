//
//  ViewController.swift
//  Document Scanner
//
//  Created by Convergent Infoware on 09/04/20.
//  Copyright © 2020 Convergent Infoware. All rights reserved.
//

import UIKit
import Vision

class CollectionFaceCell : UICollectionViewCell{
    
    @IBOutlet weak var imgFace : UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}


class ViewController: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource {
    
    
    @IBOutlet weak var img : UIImageView!
    @IBOutlet weak var textView : UITextView!
    @IBOutlet weak var collectionView : UICollectionView!
    
    var smartDoc : SmartDocRecognize?
    var faces = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        smartDoc = SmartDocRecognize(delegate: self)
        smartDoc?.needFlashButton = true
        smartDoc?.needCameraPositionButton = true
    }
    
    @IBAction func btnClickMeTessract(){
        smartDoc?.autoDetectTimerSecond = 10
        smartDoc?.startScanning(self)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return faces.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionFaceCell", for: indexPath) as! CollectionFaceCell
        cell.imgFace.image = faces[indexPath.row]
        return cell
    }
    
    
}


extension ViewController : SmartDocRecognizeDelegate{
    func didScannedComplete(_ with: SmartDocResult?, _ selectType: SmartDocumentType, data: AllSmartDocData?, _ err: Error?) {
        self.faces = [UIImage]()
        print(selectType)
        if err != nil{
            textView.text = err.debugDescription
        }else{
            img.image = with?.cropped
            if selectType == .passport{
                self.faces.append(data?.passportData?.passportImage ?? UIImage())
                self.collectionView.reloadData()
                textView.text = ("Type : \(data?.passportData?.documentType ?? "")\nCountry : \(data?.passportData?.countryCode ?? "")\nNumber : \(data?.passportData?.documentNumber ?? "")\nName : \(data?.passportData?.givenNames ?? "")\nSurname  : \(data?.passportData?.surnames ?? "")\nDOB : \(data?.passportData?.birthdate?.description ?? "")\nExp : \(data?.passportData?.expiryDate?.description ?? "")")
            }else if selectType == .license_Plate{
                self.faces.append(data?.licensePlateData?.plateImage ?? UIImage())
                self.collectionView.reloadData()
                textView.text = ("Number : \(data?.licensePlateData?.plateNumber ?? "")")
            }else if selectType == .credit_Card{
                textView.text = ("Card No : \(data?.creditCardData?.cardNumber ?? "")\nExpiry : \(data?.creditCardData?.expiryMonth ?? "")/\(data?.creditCardData?.expiryYear ?? "") \nName : \(data?.creditCardData?.name ?? "")")
            }else if selectType == .driver_License{
                self.faces.append(data?.drivingLicenseData?.faceImage ?? UIImage())
                textView.text = ("Licence No : \(data?.drivingLicenseData?.licenceNo ?? "")\nExpiry : \(data?.drivingLicenseData?.expDate?.description ?? "")\nDateOfBirth : \(data?.drivingLicenseData?.dateOfBirth?.description ?? "")\nFName : \(data?.drivingLicenseData?.firstName ?? "")\nLName : \(data?.drivingLicenseData?.lastName ?? "")")
            }else if selectType == .tax_Code_Card{
                self.faces.append(data?.taxCardData?.faceImage ?? UIImage())
                self.collectionView.reloadData()
                textView.text = ("CardNo : \(data?.taxCardData?.cardNumber ?? "")\nFName : \(data?.taxCardData?.firstName ?? "")\nLName : \(data?.taxCardData?.lastName ?? "")\nGender : \(data?.taxCardData?.gender?.rawValue ?? "")\nDOB : \(data?.taxCardData?.dateOfBirth?.description ?? "")\nExp : \(data?.taxCardData?.expDate?.description ?? "")")
            }else{
                self.faces.append(data?.othersIDCardData?.faceImage ?? UIImage())
                self.collectionView.reloadData()
                textView.text = ("Doc No : \(data?.othersIDCardData?.documentNumber ?? "")\nFName : \(data?.othersIDCardData?.firstName ?? "")\nLName : \(data?.othersIDCardData?.lastName ?? "")\nType : \(data?.othersIDCardData?.documentType ?? "")\nDOB : \(data?.othersIDCardData?.birthdate?.description ?? "")\nExp : \(data?.othersIDCardData?.expiryDate?.description ?? "")\nTax No : \(data?.othersIDCardData?.taxCodeCard ?? "")")
            }
            collectionView.reloadData()
        }
    }
    
    
    fileprivate func mrzLines(from recognizedText: String) -> [String]? {
        let mrzString = recognizedText.replacingOccurrences(of: " ", with: "")
        var mrzLines = mrzString.components(separatedBy: "\n").filter({ !$0.isEmpty })
        if !mrzLines.isEmpty {
            let averageLineLength = (mrzLines.reduce(0, { $0 + $1.count }) / mrzLines.count)
            mrzLines = mrzLines.filter({ $0.count >= averageLineLength })
        }
        
        return mrzLines.isEmpty ? nil : mrzLines
    }
    
}
