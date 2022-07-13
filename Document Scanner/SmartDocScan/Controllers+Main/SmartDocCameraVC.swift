//
//  SmartDocCameraVC.swift
//  Smart Doc Recognizer
//
//  Created by Avijit Babu on 08/04/20.
//

import AVFoundation
import Foundation
import UIKit
import AudioToolbox

public var imageForOtherCard = [UIImage]()
public var otherCardProcess = 0

class SmartDocCameraVC: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    public var preset: AVCaptureSession.Preset = .high
    public var videoGravity: AVLayerVideoGravity = .resizeAspectFill
    public var lowLightBoost: Bool = false
    public var tapToFocus: Bool = false
    public var timerOfAlertIfNotDetectSec : Int?
    public var needFlashButton : Bool = false
    public var needCameraPositionButton : Bool = false
    public var flashMode: AVCaptureDevice.FlashMode = .off
    public var cameraOrientation : AVCaptureVideoOrientation = .portrait
    public var docType : SmartDocumentType = .others_Id
    public var cameraPosition: AVCaptureDevice.Position = .back{
        didSet{
            self.reCreateSession()
        }
    }
    private(set) var cameraSession: AVCaptureSession = AVCaptureSession()
    private(set) var previewLayer: AVCaptureVideoPreviewLayer?
    private var trackView = DetectedAreaView()
    public var autoDetector = AutoDetector(){
        didSet{
            autoDetector.delegate = self
        }
    }
    var firstPageScanTitle : String = "Scan your first page of id card"
    var secondPageScanTitle : String = "Now scan another page of your id card"
    private var result : SmartDocResult?
    private var timer : Timer?
    public var rectangleDetector: SequenceRectangleDetector = NoSequenceRectangleDetector() {
        didSet {
            configureDetector()
        }
    }
    //public weak var scannerDelegate: SmartDocumentScannerDelegate?
    private var isAlertOn : Bool = false
    public var scannerMain : SmartDocRecognize?
    private var captureDevice: AVCaptureDevice?
    private var captureDeviceInput: AVCaptureDeviceInput?
    private var capturePhotoOutput: AVCapturePhotoOutput?
    private var captureVideoOutput: AVCaptureVideoDataOutput?
    private var captureMetadataOutput : AVCaptureMetadataOutput?
    private var captureBtn : UIButton!
    private var indicator = SmartDocIndicator(text: "Processing..")
    //public weak var cameraDelegate: CameraViewControllerDelegate?

    //Load everything when camera permission granted
    open override func viewDidLoad() {
        super.viewDidLoad()
        imageForOtherCard = [UIImage]()
        if docType == .license_Plate || docType == .others_Id{
            DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                self.setCapture()
            }
        }else{
            timer = Timer.scheduledTimer(withTimeInterval: Double(timerOfAlertIfNotDetectSec ?? 10), repeats: false, block: { (time) in
                self.isAlertOn = true
                self.autoDetector.reset()
                self.trackView.update(path: nil)
                DispatchQueue.main.async {
                    guard self.cameraSession.isRunning else { return }
                    self.cameraSession.stopRunning()
                }
                self.showSingleButtonAlertWithAction(title: "Not Detect", buttonTitle: "Let's Capture", message: "We are sorry that we not able to detect your document with our auto detection technique.But you can manualy capture and crop doc process.") {
                    self.setCapture()
                    time.invalidate()
                    self.isAlertOn = false
                    self.autoDetector.reset()
                    self.trackView.update(path: nil)
                    DispatchQueue.main.async {
                        guard !self.cameraSession.isRunning else { return }
                        self.cameraSession.startRunning()
                    }
                }
            })
        }
        
        navigationItem.title = "Camera"
        checkAndUpdateBar()
        let previewLayer = AVCaptureVideoPreviewLayer(session: cameraSession)
        previewLayer.videoGravity = videoGravity
        previewLayer.connection?.videoOrientation = cameraOrientation
        self.view.layer.insertSublayer(previewLayer, at: 0)
        self.previewLayer = previewLayer
        SmartHelper.defaults.canGetPermission(from: self) { (success) in
            if success{
                self.createSession()
//                self.cameraDelegate?.cameraViewController(update: .authorized)
            }
        }
        if #available(iOS 11.0, *) {
            rectangleDetector = VisionSequenceRectangleDetector()
        }
        autoDetector.delegate = self
    }
    
    private func setCapture(){
        self.captureBtn = UIButton(frame: CGRect(x: (self.view.frame.width / 2) - 30, y: (self.view.frame.height) - 80 , width: 60, height: 60))
        self.captureBtn.layer.cornerRadius = 30
        self.captureBtn.layer.borderWidth = 3
        self.captureBtn.layer.borderColor = UIColor.black.cgColor
        self.captureBtn.backgroundColor = .white
        self.captureBtn.clipsToBounds = true
        self.view.addSubview(captureBtn)
        captureBtn.addTarget(self, action: #selector(clickToCapture), for: .touchUpInside)
    }
    
    @objc func clickToCapture(){
        takePhoto()
    }
    
    /**
     * Set flash or camera swap icon on top
     */
    private func checkAndUpdateBar(){
        let camera = UIBarButtonItem(image: UIImage(named: "camera_rotate"), style: .plain, target: self, action: #selector(rotateCamera))
        let flash = UIBarButtonItem(image: UIImage(named: "flash"), style: .plain, target: self, action: #selector(flashCamera))
        if needCameraPositionButton && needFlashButton{
            self.navigationItem.setRightBarButtonItems([camera,flash], animated: true)
        }else{
            if needCameraPositionButton{
                self.navigationItem.setRightBarButton(camera, animated: true)
            }else if needFlashButton{
                self.navigationItem.setRightBarButton(flash, animated: true)
            }else{
                self.navigationItem.setRightBarButton(nil, animated: true)
            }
        }
    }
    
    //Rotate camera action
    @objc private func rotateCamera(){
        if cameraPosition == .back{
            cameraPosition = .front
        }else{
            cameraPosition = .back
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
                    try device.setTorchModeOn(level: 1.0)
                } catch {
                    print(error)
                }
            }
            device.unlockForConfiguration()
        } catch {
            self.showSingleButtonAlertWithAction(title: "Flashlight Error.", buttonTitle: "OK", message: "") {
                self.reCreateSession()
            }
        }
    }

    //When detect complete or this page gone then we will stop camera session
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        autoDetector.reset()
        trackView.update(path: nil)
        DispatchQueue.main.async {
            guard self.cameraSession.isRunning else { return }
            self.cameraSession.stopRunning()
        }
    }

    //Every time back to this page we reprocess the session
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if docType == .license_Plate && (NSString(string : UIDevice.current.systemVersion).floatValue < 13.0){
            self.showSingleButtonAlertWithAction(title: "Waring", buttonTitle: "OK", message: "If you are using a iPhone of OS version of 13.0 then it will give you the better result than the older version of iPhone.") {
                
            }
        }
        if self.docType == .others_Id{
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
            if otherCardProcess == 0{
                alert.title = firstPageScanTitle
                self.present(alert, animated: true, completion: {
                    sleep(2)
                    alert.dismiss(animated: true, completion: nil)
                    self.autoDetector.reset()
                    self.trackView.update(path: nil)
                    DispatchQueue.main.async {
                        guard !self.cameraSession.isRunning else { return }
                        self.cameraSession.startRunning()
                    }
                })
                return
            }else if otherCardProcess == 1{
                alert.title = secondPageScanTitle
                self.present(alert, animated: true, completion: {
                    sleep(2)
                    alert.dismiss(animated: true, completion: nil)
                    self.autoDetector.reset()
                    self.trackView.update(path: nil)
                    DispatchQueue.main.async {
                        guard !self.cameraSession.isRunning else { return }
                        self.cameraSession.startRunning()
                    }
                })
                return
            }
        }
        self.autoDetector.reset()
        self.trackView.update(path: nil)
        DispatchQueue.main.async {
            guard !self.cameraSession.isRunning else { return }
            self.cameraSession.startRunning()
        }
    }

    //This update every time when view layout change. We update everything here.
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        previewLayer?.videoGravity = videoGravity
        trackView.frame = view.bounds
        trackView.layoutSubviews()
        previewLayer?.connection?.videoOrientation = .portrait
    }
    
    //Configure detected area
    private func configureDetector() {
        rectangleDetector.update = { [weak self] observation in
            guard let strongSelf = self else { return }
            strongSelf.autoDetector.feed(observation: observation)
        }
    }
    
    //When auto detect failed then you can take photo to proceed. Here is the func to capture
    //After take capture deleagte fun will call
    public func takePhoto() {
        guard let output = capturePhotoOutput, cameraSession.isRunning else { return }
        let settings = AVCapturePhotoSettings()
        settings.flashMode = flashMode
        settings.isHighResolutionPhotoEnabled = true
        if #available(iOS 13, *){
        }else{
            settings.isAutoStillImageStabilizationEnabled = true
        }
        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first ?? 0
        let previewFormat = [
            kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
            kCVPixelBufferWidthKey as String: 160,
            kCVPixelBufferHeightKey as String: 160
        ]
        settings.previewPhotoFormat = previewFormat
        output.capturePhoto(with: settings, delegate: self)
    }

    //Touch on camera to focus
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard tapToFocus, let touch = touches.first else { return }
        let location = touch.preciseLocation(in: view)
        let size = view.bounds.size
        let focusPoint = CGPoint(x: location.x / size.height, y: 1 - location.x / size.width)
        guard let captureDevice = captureDevice else { return }
        do {
            try captureDevice.lockForConfiguration()
            if captureDevice.isFocusPointOfInterestSupported {
                captureDevice.focusPointOfInterest = focusPoint
                captureDevice.focusMode = .autoFocus
            }
            if captureDevice.isExposurePointOfInterestSupported {
                captureDevice.exposurePointOfInterest = focusPoint
                captureDevice.exposureMode = .continuousAutoExposure
            }
            captureDevice.unlockForConfiguration()
            //cameraDelegate?.cameraViewController(didFocus: location)
        } catch {
            print(error)
        }
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        rectangleDetector.detect(on: pixelBuffer)
    }

}

extension SmartDocCameraVC {

    //Re create camera session after back to camera vc
    private func reCreateSession() {
        DispatchQueue.main.async {
            let inputs = self.cameraSession.inputs
            inputs.forEach { self.cameraSession.removeInput($0) }
            self.captureDevice = nil
            self.captureDeviceInput = nil
            self.configureCaptureDevice()
            self.configureCaptureDeviceInput()
            self.configureQRBarCaptureOutput()
            if !self.trackView.isDescendant(of: self.view){
                self.view.addSubview(self.trackView)
            }
        }
    }

    //Create camera session first time
    private func createSession() {
        DispatchQueue.main.async {
            self.cameraSession.beginConfiguration()
            if self.cameraSession.canSetSessionPreset(self.preset) {
                self.cameraSession.sessionPreset = self.preset
            } else {
                self.cameraSession.sessionPreset = .high
            }
            self.configureCaptureDevice()
            self.configureCaptureDeviceInput()
            self.configureQRBarCaptureOutput()
            self.configureCapturePhotoOutput()
            self.configureCaptureVideoOutput()
            self.cameraSession.commitConfiguration()
            self.cameraSession.startRunning()
            if !self.trackView.isDescendant(of: self.view){
                self.view.addSubview(self.trackView)
            }
        }
    }

    //Set up when capture occur from this we will capture the photo. Here we setting up of it.
    private func configureCaptureDevice() {
        let device = captureDevice(for: cameraPosition)
        guard let captureDevice = device else { return }

        do {
            try captureDevice.lockForConfiguration()

            if captureDevice.isFocusModeSupported(.continuousAutoFocus) {
                captureDevice.focusMode = .continuousAutoFocus
            }

            if captureDevice.isSmoothAutoFocusSupported {
                captureDevice.isSmoothAutoFocusEnabled = true
            }

            if captureDevice.isExposureModeSupported(.continuousAutoExposure) {
                captureDevice.exposureMode = .continuousAutoExposure
            }

            if captureDevice.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                captureDevice.whiteBalanceMode = .continuousAutoWhiteBalance
            }

            if captureDevice.isLowLightBoostSupported && lowLightBoost {
                captureDevice.automaticallyEnablesLowLightBoostWhenAvailable = true
            }

            captureDevice.unlockForConfiguration()
        } catch {
            print(error)
        }
        self.captureDevice = captureDevice
    }

    private func configureCaptureDeviceInput() {
        do {
            guard let captureDevice = captureDevice else { return }
            let captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)

            if cameraSession.canAddInput(captureDeviceInput) {
                cameraSession.addInput(captureDeviceInput)
            }
            self.captureDeviceInput = captureDeviceInput
        } catch {
            print(error)
        }
    }
    //If doc have qr or barcode. This method is setting up for that.
    private func configureQRBarCaptureOutput(){
        guard let captureOut = captureMetadataOutput else { return }
        captureOut.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        captureOut.metadataObjectTypes = [.ean13,.qr]
        if cameraSession.canAddOutput(captureOut){
            cameraSession.addOutput(captureOut)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("Now it's over. It shows memory warning")
    }

    //This setup help us capture photo every time from camera.
    private func configureCapturePhotoOutput() {
        let capturePhotoOutput = AVCapturePhotoOutput()
        capturePhotoOutput.isHighResolutionCaptureEnabled = true
        if #available(iOS 13, *){
        }else{
            if capturePhotoOutput.isDualCameraDualPhotoDeliverySupported {
                capturePhotoOutput.isDualCameraDualPhotoDeliveryEnabled = true
            }
        }
        if cameraSession.canAddOutput(capturePhotoOutput) {
            cameraSession.addOutput(capturePhotoOutput)
        }
        self.capturePhotoOutput = capturePhotoOutput
    }

    //This setup help us capture video every time from camera.
    private func configureCaptureVideoOutput() {
        let captureVideoOutput = AVCaptureVideoDataOutput()
        captureVideoOutput.alwaysDiscardsLateVideoFrames = true
        captureVideoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "cameraQueue"))
        if cameraSession.canAddOutput(captureVideoOutput) {
            cameraSession.addOutput(captureVideoOutput)
        }
        self.captureVideoOutput = captureVideoOutput
    }

    private func captureDevice(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let session = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: position)
        let devices = session.devices
        let wideAngle = devices.first { $0.position == position }
        return wideAngle
    }
    /*
    func processOtherDocuments(){
        DispatchQueue.global(qos: .background).async{
            if imageForOtherCard.count >= 2{
                DispatchQueue.main.async {
                    let older = ProcessDataTessract(imageForOtherCard.last ?? UIImage(),type: self.docType)
                    older.process()
                    older.getText = { res,err in
                        if self.docType == .others_Id{
                            if otherCardProcess >= 2{
                                self.indicator.hide()
                                self.navigationController?.dismiss(animated: true, completion: {
                                    self.scannerMain?.delegate?.didScannedComplete(self.result, self.docType, data: res, err)
                                })
                            }
                        }
                    }
                }
            }else{
                let older = ProcessDataTessract(imageForOtherCard.first ?? UIImage(),type: self.docType)
                older.process()
            }
        }
    }*/
}

extension SmartDocCameraVC: AVCapturePhotoCaptureDelegate {

    @available(iOS 11.0, *)
    //photo capture deleage over iOS version 11
    //This will call when you click on capture button
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else { return }
            DispatchQueue.main.async { [weak self] in
                let cropVC = SmartDocCropVC()
                cropVC.captureImage = image
                cropVC.scannerMain = self?.scannerMain
                cropVC.cameraVC = self
                cropVC.docType = self?.docType ?? SmartDocumentType.others_Id
                self?.navigationController?.pushViewController(cropVC, animated: true)
                self?.timer?.invalidate()
                //self?.cameraDelegate?.cameraViewController(captured: image)
            }
        }
    }

    //photo capture deleage for older of iOS version 11
    //This will call when you click on capture button
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        if #available(iOS 11.0, *) { } else {
            DispatchQueue.global(qos: .userInitiated).async {
                guard let sampleBuffer = photoSampleBuffer, let data = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: nil), let image = UIImage(data: data) else { return }
                DispatchQueue.main.async { [weak self] in
                    let cropVC = SmartDocCropVC()
                    cropVC.captureImage = image
                    cropVC.scannerMain = self?.scannerMain
                    cropVC.cameraVC = self
                    cropVC.docType = self?.docType ?? SmartDocumentType.others_Id
                    self?.navigationController?.pushViewController(cropVC, animated: true)
                    self?.timer?.invalidate()
//                    self?.cameraDelegate?.cameraViewController(captured: image)
                }
            }
        }
    }

}

//Here all protocol declear when camera caught any document
extension SmartDocCameraVC : AutoDetectorDelegate{
    
    //Protocol to update scanned captureImage area
    public func detector(update: Observation) {
        guard let points = update.quad?.mirrorUp()?.points else { return }
        let converted = points.compactMap { previewLayer?.layerPointConverted(fromCaptureDevicePoint: $0) }
        let path = converted.quadPath
        trackView.update(path: path)
    }
    
    @objc private func closePage(){
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    //Final detection of document
    public func detector(success: Observation) {
        guard let quad = success.quad, let mirrored = quad.mirrorUp() else { return }
        
        CropHelper.crop(buffer: success.buffer, quad: mirrored) { result in
            if self.isAlertOn {
                return
            }
            self.result = result
            if let img = result.cropped{
                self.navigationController?.view.isUserInteractionEnabled = false
                self.timer?.invalidate()
                AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                self.autoDetector.reset()
                self.trackView.update(path: nil)
                guard self.cameraSession.isRunning else { return }
                self.cameraSession.stopRunning()
                imageForOtherCard.append(img)
                if otherCardProcess >= 1{
                    if #available(iOS 13.0, *) {
                        
                        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(self.closePage)), animated: true)
                    } else {
                        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.closePage)), animated: true)
                    }
                }
                if !self.indicator.isDescendant(of: self.view){
                    self.view.addSubview(self.indicator)
                }
                self.indicator.show()
                DispatchQueue.main.async {
                    let older = ProcessDataTessract(img,type: self.docType)
                    older.process()
                    older.getText = { res,err in
                        if self.docType == .others_Id{
                            if otherCardProcess == 1{
                                self.indicator.hide()
                                let alert = UIAlertController(title: self.secondPageScanTitle, message: nil, preferredStyle: .alert)
                                self.present(alert, animated: true, completion: {
                                    sleep(2)
                                    alert.dismiss(animated: true) {
                                        self.autoDetector.reset()
                                        self.trackView.update(path: nil)
                                        guard !self.cameraSession.isRunning else { return }
                                        self.cameraSession.startRunning()
                                    }
                                })
                                self.navigationController?.view.isUserInteractionEnabled = true
                                return
                            }else if otherCardProcess >= 2{
                                self.indicator.hide()
                                self.navigationController?.dismiss(animated: true, completion: {
                                    self.scannerMain?.delegate?.didScannedComplete(result, self.docType, data: res, err)
                                })
                            }
                        }else{
                            self.indicator.hide()
                            self.navigationController?.dismiss(animated: true, completion: {
                                self.scannerMain?.delegate?.didScannedComplete(result, self.docType, data: res, err)
                            })
                        }
                        self.navigationController?.view.isUserInteractionEnabled = true
                    }
                }
            }else{
                DispatchQueue.main.async {
                    self.timer?.invalidate()
                    self.navigationController?.dismiss(animated: true, completion: {
                        self.scannerMain?.delegate?.didScannedComplete(nil, self.docType, data: nil, NSError(domain: "Error", code: -1002, userInfo: ["err" : "Image not found."]))
                    })
                }
            }
            //self.scannerDelegate?.documentScanner(result: result)
        }
    }
    //When camera can't detect any document
    public func detector(failed: Observation) {
        trackView.update(path: nil)
    }
}

extension SmartDocCameraVC : AVCaptureMetadataOutputObjectsDelegate{
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        print("Deletegate called")
        if let metadataObj = metadataObjects.first as? AVMetadataMachineReadableCodeObject {
            myCardQrOrBarResult = metadataObj.stringValue ?? ""
        }
    }
    
}
