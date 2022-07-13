//
//  SmartDocCropVC.swift
//  Smart Doc Recognizer
//
//  Created by Avijit Babu on 08/04/20.
//

import UIKit
import Vision
import AudioToolbox


/**
 * This is the main class of the capturer document crop.
 */
class SmartDocCropVC: UIViewController {

    //Captured image view
    public var scannerMain : SmartDocRecognize?
    private var cropImageView : UIImageView!
	public private(set) var cropView = SDRCropView()
    public var docType : SmartDocumentType = .others_Id
	private var points: [CGPoint] = [] {
		didSet {
			updateCropview()
		}
	}
	private var configuredCropView: Bool = false
	private var rectangleDetector: ImageRectangleDetector = CIImageRectangleDetector()

    // pass the captured image here image
	public var captureImage: UIImage? {
		didSet {
            //Update croped area's image and set it to own
			captureImage = captureImage?.fixOrientation()
		}
	}
    private var indicator = SmartDocIndicator(text: "Processing..")
    var cameraVC : SmartDocCameraVC?
//	public weak var cropDelegate: DocumentCropViewControllerDelegate?

	open override func viewDidLoad() {
		super.viewDidLoad()
        navigationItem.title = "Smart Crop"
        if #available(iOS 11.0, *) {
            rectangleDetector = VisionImageRectangleDetector()
        }
        self.navigationItem.setRightBarButton(UIBarButtonItem(title: "Process", style: .plain , target: self, action: #selector(doneCrop)), animated: true)
        UIView.animate(withDuration: 0.5) {
            self.cropImageView = UIImageView(frame: self.view.frame)
            self.cropImageView.center = self.view.center
            if !self.cropImageView.isDescendant(of: self.view){
                self.view.addSubview(self.cropImageView)
            }
            SDRCropView.goodAreaColor = .systemBlue
            SDRCropView.badAreaColor = .systemRed
            self.configure()
        }
	}
    
    @objc private func doneCrop(){
        if !indicator.isDescendant(of: self.view){
            self.view.addSubview(self.indicator)
        }
        self.indicator.show()
        self.crop()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        cropView.frame = view.bounds
        cropView.layoutSubviews()
        updateCropview()
    }

	public func configure() {
        captureImage = captureImage?.fixOrientation()
        cropImageView.transform = CGAffineTransform.identity
        cropImageView.image = captureImage
        cropImageView.contentMode = .scaleAspectFit
        points = defaultCropViewCorners()
        guard let image = captureImage else { return }
        rectangleDetector.detect(image: image, completion: handleDetection)
	}

    //Update
	private func updateCropview() {
		let size = captureImage?.size ?? .zero
		let width = Int(size.width)
		let height = Int(size.height)

		let converted: [CGPoint]

		if #available(iOS 11, *) {
			converted = points.map { VNImagePointForNormalizedPoint($0, width, height) }
		} else {
			converted = points.map { $0.scaledAbsolute(size: size) }
		}
		updateCorners(points: converted.map { $0.cartesian(height: size.height) })
	}

    //Chage the corner
	private func updateCorners(points: [CGPoint]) {
		if configuredCropView {
			cropView.setCorners(newCorners: points)
		} else {
			cropView.configureWithCorners(corners: points, on: cropImageView)
			configuredCropView = true
		}
	}

    //Handle the detection any swaping corner
	private func handleDetection(quad: RectangularSwap?) {
		if let quad = quad {
			points = quad.points
		} else {
			points = defaultCropViewCorners()
		}
	}

	private func defaultCropViewCorners() -> [CGPoint] {
		return [CGPoint(x: 0.2, y: 0.2), CGPoint(x: 0.2, y: 0.8), CGPoint(x: 0.8, y: 0.8), CGPoint(x: 0.8, y: 0.2)]
	}

    //pass error or result when crop is completed
	private func crop() {
		guard let image = captureImage, let points = cropView.cornerLocations else { return }
		DispatchQueue.global(qos: .userInitiated).async {
			do {
				let croppedImage = try SDRQuadrangleHelper.cropImage(with: image, quad: points)
				let result = SmartDocResult(original: image, cropped: croppedImage, quad: RectangularSwap(clockwise: points))
				DispatchQueue.main.async {
                    if let img = result.cropped{
                        self.navigationController?.view.isUserInteractionEnabled = false
                        imageForOtherCard.append(img)
                        let older = ProcessDataTessract(img, type: self.docType)
                        older.process()
                        older.getText = { res,err in
                            if self.docType == .others_Id{
                                if otherCardProcess == 1{
                                    self.indicator.hide()
                                    AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                                    self.navigationController?.popViewController(animated: true)
                                }else if otherCardProcess >= 2{
                                    self.indicator.hide()
                                    AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                                    self.scannerMain?.delegate?.didScannedComplete(result, self.docType, data: res, err)
                                    self.navigationController?.dismiss(animated: true, completion: nil)
                                }
                            }else{
                                self.indicator.hide()
                                AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                                self.scannerMain?.delegate?.didScannedComplete(result, self.docType, data: res, err)
                                self.navigationController?.dismiss(animated: true, completion: nil)
                            }
                            self.navigationController?.view.isUserInteractionEnabled = true
                        }
                    }else{
                        self.indicator.hide()
                        self.scannerMain?.delegate?.didScannedComplete(nil, self.docType, data: nil, NSError(domain: "Error", code: -1002, userInfo: ["err" : "Image not found."]))
                        self.navigationController?.dismiss(animated: true, completion: nil)
                    }
                    //self?.cropDelegate?.documentCropViewController(result: result)
				}
			} catch {
				DispatchQueue.main.async {
                    self.scannerMain?.delegate?.didScannedComplete(nil, self.docType, data: nil,error)
                    self.navigationController?.dismiss(animated: true, completion: nil)
                    //self?.cropDelegate?.documentCropViewController(failed: error)
				}
			}
		}
	}

}
