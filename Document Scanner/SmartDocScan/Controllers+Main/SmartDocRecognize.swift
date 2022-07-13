//
//  SmartDocRecognize.swift
//  Smart Doc Recognizer
//
//  Created by Avijit Babu on 08/04/20.
//

import Foundation
import UIKit
import AVFoundation
/**
 * This is the main protocol where you will find result of your document scan.
 */
public protocol SmartDocRecognizeDelegate{
    /**
     * This func will call everytime when we finish the scan. If delegate extend then it will call.
     */
    func didScannedComplete(_ with : SmartDocResult?,_ selectType : SmartDocumentType,data : AllSmartDocData?,_ err : Error?)
}

/**
 * Enum for language list of this framework.
 */

public enum SmartScanLanguage{
    case english
    case italic
}

/**
 * This is the main class of the docment scanner. You need to initialize and create an object of this class to use.
 */
public class SmartDocRecognize: NSObject{
    
    /**
     * Pass your first page scanning alert title of two page type
     */
    public var firstPageScanTitle : String = "Scan your first page of id card"
    
    /**
     * Pass your second page scanning alert title of two page type
     */
    public var secondPageScanTitle : String = "Now scan another page of your id card"
    
    /**
     * Pass your timer second, if detection fails then we show an alert after this amount of second.
     */
    public var autoDetectTimerSecond : Int? = 10
    
    /**
     * If low light boost is on then we use low light sensor if it is available in your device. Default value is  10 second
     */
    public var lowLightBoost: Bool = false
    
    /**
     * Pass your peferred langauge and we set that language accordingly default is english.
     */
    public var languageType: SmartScanLanguage = .italic
    
    /**
     * Tap to focus when you tap on camera it focus to document object. Default value is false.
     */
    public var tapToFocus: Bool = false
    /**
     * If need a flash button then we add flash button on top navigation. You can turn on and off flash using this. Default value is false.
     */
    public var needFlashButton : Bool = false
    /**
     * You can choose the flash mode. It's default set to off. you can set it to on or auto if its set auto then flash light on when capture.
     */
    public var flashMode : AVCaptureDevice.FlashMode = .off
    /**
     * If need a camera postion button then we add camera icon on top navigation. You can swap back and front camera using this. Default value is false.
     */
    public var needCameraPositionButton : Bool = false
    /**
     * Set the delagate from that where you need it and make sure that you will extend our protocol SmartDocRecognizeDelegate.
     */
    public var delegate : SmartDocRecognizeDelegate?
    
    public convenience init(delegate : SmartDocRecognizeDelegate){
        self.init()
        self.delegate = delegate
    }
    
//    public convenience init(language : SmartScanLanguage){
//        self.init()
//        self.languageType = language
//    }
    
    public convenience init(detectionTime : Int){
        self.init()
        self.autoDetectTimerSecond = detectionTime
    }
    
    /**
     * Call this func when you need to present the document scanner. It will set a navigation bar on the top.
     */
    public func startScanning(_ from : UIViewController){
        let firstVC = ListCardTableVC()
        firstVC.scannerMain = self
        firstVC.timerOfAlertIfNotDetectSec = self.autoDetectTimerSecond
        firstVC.lowLightBoost = self.lowLightBoost
        firstVC.tapToFocus = self.tapToFocus
        firstVC.flashMode = self.flashMode
        firstVC.needFlashButton = self.needFlashButton
        firstVC.firstPageScanTitle = self.firstPageScanTitle
        firstVC.secondPageScanTitle = self.secondPageScanTitle
        firstVC.needCameraPositionButton = self.needCameraPositionButton
        let nav = UINavigationController(rootViewController: firstVC)
        nav.navigationBar.isTranslucent = false
        if #available(iOS 13.0, *) {
            nav.modalPresentationStyle = .fullScreen
        }
        from.present(nav, animated: true, completion: {
            myCardQrOrBarResult = ""
        })
    }
    
}

public enum SmartDocumentType : String{
    case passport = "Passport"
    case driver_License = "Driver License"
    case license_Plate = "License Plate"
    case tax_Code_Card = "Tax Code Card"
    case credit_Card = "Credit card"
    case others_Id = "Identity card in paper and card format"
}

//This this the first list controller
class ListCardTableVC: UITableViewController{
    
    private var items : [SmartDocumentType] = [.passport,.driver_License,.license_Plate,.tax_Code_Card,.credit_Card,.others_Id]
    public var scannerMain : SmartDocRecognize?
    public var timerOfAlertIfNotDetectSec : Int?
    public var lowLightBoost: Bool = false
    public var tapToFocus: Bool = false
    public var flashMode : AVCaptureDevice.FlashMode = .off
    public var needFlashButton : Bool = false
    public var needCameraPositionButton : Bool = false
    public var firstPageScanTitle : String!
    public var secondPageScanTitle : String!
    var closeButton : UIBarButtonItem{
        if #available(iOS 13.0, *) {
            return UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closePage))
        } else {
            return UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(closePage))
        }
        
    }
    var infoButton : UIBarButtonItem{
        if #available(iOS 13.0, *) {
            return UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(info))
        } else {
            return UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(info))
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SmartHelper.defaults.canGetPermission(from: self)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.tableFooterView = UIView()
        self.navigationItem.setRightBarButtonItems([infoButton,closeButton], animated: true)
        navigationItem.title = "Choose Type"
    }
    
    @objc private func closePage(){
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @objc private func info(){
        self.showSingleButtonAlertWithAction(title: "Information", buttonTitle: "Ok", message: "Please scan your document just near to camera. Keep your document's width fitted with the mobile screen width with proper zooming for better result.") {
            
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        cell.selectionStyle = .none
        cell.textLabel?.text = items[indexPath.row].rawValue
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if items[indexPath.row] == .credit_Card{
            let cardScan = SmartCardRecognizerVC()
            cardScan.needFlashButton = self.needFlashButton
            cardScan.scannerMain = self.scannerMain
            cardScan.docType = items[indexPath.row]
            self.navigationController?.pushViewController(cardScan, animated: true)
        }else{
            let scanner = SmartDocCameraVC()
            scanner.scannerMain = self.scannerMain
            scanner.timerOfAlertIfNotDetectSec = self.timerOfAlertIfNotDetectSec
            scanner.lowLightBoost = self.lowLightBoost
            scanner.docType = items[indexPath.row]
            scanner.tapToFocus = self.tapToFocus
            scanner.flashMode = self.flashMode
            scanner.firstPageScanTitle = self.firstPageScanTitle
            scanner.secondPageScanTitle = self.secondPageScanTitle
            otherData = IDCardData()
            otherCardProcess = 0
            imageForOtherCard = [UIImage]()
            scanner.needFlashButton = self.needFlashButton
            scanner.needCameraPositionButton = self.needCameraPositionButton
            SmartHelper.defaults.canGetPermission(from: self) { (success) in
                if success{
                    self.navigationController?.pushViewController(scanner, animated: true)
                }else{
                    let err = NSError(domain: "Camera", code: -1233, userInfo: ["Error" : "Camera not permit me to scan. Please allow me camera."])
                    self.scannerMain?.delegate?.didScannedComplete(nil,self.items[indexPath.row], data: nil, err)
                    self.navigationController?.dismiss(animated: true)
                }
            }
        }
    }
    
}
