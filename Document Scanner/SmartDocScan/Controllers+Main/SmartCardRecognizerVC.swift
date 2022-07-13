//
//  SmartCardRecognizerVC.swift
//  SmartCardRecognizer
//
//  Created by Avijit Babu on 17/04/20.
//  Copyright © 2017 Wallet One. All rights reserved.
//

import UIKit
import PayCardsRecognizer
import AVFoundation

final class SmartCardRecognizerVC: UIViewController {
    
    private var recognizer: PayCardsRecognizer!
    public var needFlashButton : Bool = true
    public var docType : SmartDocumentType = .credit_Card
    public var scannerMain : SmartDocRecognize?
    let toolbar = UIToolbar()
    
    lazy var activityView: UIBarButtonItem = {
        let activityView = UIActivityIndicatorView(style: .gray)
        activityView.startAnimating()
        let item = UIBarButtonItem(customView: activityView)
        return item
    }()
    private var sliderValue : Float = 0.5
    var flash = UIBarButtonItem()
    
    // MARK: - VC Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addSlider()
        checkAndUpdateBar()
        self.navigationItem.title = "Camera"
        recognizer = PayCardsRecognizer(delegate: self, resultMode: .async, container: self.view, frameColor: .systemBlue)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        recognizer.startCamera()
        addSlider()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.toolbar.isDescendant(of: self.navigationController?.view ?? UIView()){
            self.toolbar.removeFromSuperview()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    @objc func updateValue(_ sender : UISlider){
        sliderValue = sender.value
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        if device.isTorchActive{
            do{
                try device.lockForConfiguration()
                do{
                    try device.setTorchModeOn(level: sliderValue)
                }catch{
                    print(error)
                }
                device.unlockForConfiguration()
            }catch{
                print(error)
            }
        }
    }
    
    func addSlider(){
        toolbar.barStyle = UIBarStyle.default
        //Set the toolbar to fit the width of the app.
        toolbar.sizeToFit()
        //Caclulate the height of the toolbar
        let toolbarHeight = toolbar.frame.size.height
        //Get the bounds of the parent view
        let rootViewBounds = self.parent?.view.bounds
        //Get the height of the parent view.
        let rootViewHeight = rootViewBounds?.height
        //Get the width of the parent view,
        let rootViewWidth = rootViewBounds?.width
        //Create a rectangle for the toolbar
        let rectArea = CGRect(x: 0, y: rootViewHeight! - toolbarHeight, width: rootViewWidth!, height: toolbarHeight)
        //Reposition and resize the receiver
        toolbar.frame = rectArea
        //Create a button
        if !toolbar.isDescendant(of: self.navigationController?.view ?? UIView()){
            self.navigationController?.view.addSubview(toolbar)
        }
        let button = UIButton()
        button.setImage(UIImage(named : "lowB")?.withRenderingMode(.alwaysTemplate), for: .normal)
        let button1 = UIButton()
        button1.setImage(UIImage(named : "highB")?.withRenderingMode(.alwaysTemplate), for: .normal)
        let slider = UISlider()
        let stackView = UIStackView(frame: self.toolbar.frame)
        stackView.distribution = .fill
        stackView.alignment = .top
        stackView.axis = .horizontal
        stackView.addArrangedSubview(button)
        stackView.addArrangedSubview(slider)
        stackView.addArrangedSubview(button1)
        stackView.spacing = 8.0
        slider.minimumValue = 0.1
        slider.maximumValue = 1.0
        slider.thumbTintColor = UIColor.systemBlue.withAlphaComponent(0.7)
        slider.minimumTrackTintColor = .systemBlue
        slider.maximumTrackTintColor = .white
        slider.setValue(0.5, animated: true)
        slider.addTarget(self, action: #selector(self.updateValue), for: .valueChanged)
        self.toolbar.items = [UIBarButtonItem(customView: stackView)]
    }
    
    
    /**
     * Set flash or camera swap icon on top
     */
    private func checkAndUpdateBar(){
        flash = UIBarButtonItem(image: UIImage(named: "flash"), style: .plain, target: self, action: #selector(flashCamera))
        if needFlashButton{
            self.navigationItem.setRightBarButton(flash, animated: true)
        }else{
            self.navigationItem.setRightBarButton(nil, animated: true)
        }
    }
    
    
    //Flash lihght turn on or turn off
    @objc private func flashCamera(){
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        guard device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            
            if (device.torchMode == AVCaptureDevice.TorchMode.on) {
                device.torchMode = AVCaptureDevice.TorchMode.off
            } else {
                do {
                    try device.setTorchModeOn(level: sliderValue)
                } catch {
                    print(error)
                }
            }
            device.unlockForConfiguration()
        } catch {
            self.showSingleButtonAlertWithAction(title: "Flashlight Error.", buttonTitle: "OK", message: "") {
                self.recognizer.startCamera()
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        recognizer.stopCamera()
        navigationItem.rightBarButtonItems = nil
    }

}

// MARK: - PayCardsRecognizerPlatformDelegate
extension SmartCardRecognizerVC: PayCardsRecognizerPlatformDelegate {
    func payCardsRecognizer(_ payCardsRecognizer: PayCardsRecognizer, didRecognize result: PayCardsRecognizerResult) {
        if result.isCompleted {
            print(result)
            self.navigationController?.dismiss(animated: true, completion: {
                let imageReslt = SmartDocResult(original: result.image, cropped: result.image, quad: nil)
                var docData = AllSmartDocData()
                var cardData = CreditCardData()
                cardData.cardNumber = result.recognizedNumber
                cardData.finalImage = self.view.snapshot(of: result.recognizedNumberRect, afterScreenUpdates: true)
                cardData.expiryMonth = result.recognizedExpireDateMonth
                cardData.expiryYear = result.recognizedExpireDateYear
                cardData.name = result.recognizedHolderName
                docData.creditCardData = cardData
                self.scannerMain?.delegate?.didScannedComplete(imageReslt, self.docType, data: docData, nil)
            })
        } else {
            if needFlashButton{
                self.navigationItem.setRightBarButtonItems([flash,activityView], animated: true)
            }else{
                self.navigationItem.setRightBarButton(activityView, animated: true)
            }
        }
    }
}


