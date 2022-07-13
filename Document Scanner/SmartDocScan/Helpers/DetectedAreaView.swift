//
//  DetectedAreaView.swift
//  Smart Doc Recognizer
//
//  Created by Avijit Babu on 08/04/20.
//

import UIKit


//Detect any doc when open camera with doc's area
public final class DetectedAreaView: UIView {

    public static var lineColor: UIColor = .systemBlue
    public static var fillColor: UIColor = .clear
	public static var lineWidth: CGFloat = 2
	private var shape = CAShapeLayer()
	private var updated: Double = 0


	override init(frame: CGRect) {
		super.init(frame: frame)
		setup()
	}

	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setup()
	}

	private func setup() {
		shape.strokeColor = DetectedAreaView.lineColor.cgColor
		shape.fillColor = DetectedAreaView.fillColor.cgColor
		shape.lineWidth = DetectedAreaView.lineWidth
        shape.cornerRadius = 30
        layer.addSublayer(shape)
	}

	override public func layoutSubviews() {
		super.layoutSubviews()
		shape.frame = bounds
		shape.strokeColor = DetectedAreaView.lineColor.cgColor
		shape.fillColor = DetectedAreaView.fillColor.cgColor
		shape.lineWidth = DetectedAreaView.lineWidth
        shape.cornerRadius = 30
	}

	func update(path: UIBezierPath?) {
		if let path = path {
			shape.path = path.cgPath
		} else {
			shape.path = nil
		}
	}
}
