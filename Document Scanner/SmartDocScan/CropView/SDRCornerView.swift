//
//  CornerView.swift
//  Smart Doc Recognizer
//
//  Inspired by Никита Разумный on 11/04/20.
//  Copyright © 2017 Avijit and Никита Разумный. All rights reserved.
//

import UIKit

//This func set up the four corner of crop area
class SDRCornerView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = frame.size.width / 2.0
        layer.borderWidth = 1.0
        layer.masksToBounds = true
        backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let position = superview!.convert(self.frame, to: nil)
        let touchPoint = position.origin

        let context = UIGraphicsGetCurrentContext()!
        
        context.translateBy(x: -(position.size.width / 2 - SDRCropView.cornerSize / 2),
                            y: -(position.size.width / 2 - SDRCropView.cornerSize / 2))

        context.translateBy(x: -touchPoint.x,
                            y: -touchPoint.y)
    }
    
    //When tap on, it will animatedly scale up
    func scaleUp() {
        UIView.animate(withDuration: 0.15, animations: {
            self.layer.borderWidth = 0.5
            self.transform = CGAffineTransform.identity.scaledBy(x: 2, y: 2)
        }) { (_) in
            self.setNeedsDisplay()
        }
    }
    
    //When tap out, it will animatedly scale down
    func scaleDown() {
        UIView.animate(withDuration: 0.15, animations: {
            self.layer.borderWidth = 1
            self.transform = CGAffineTransform.identity
        }) { (_) in
            self.setNeedsDisplay()
        }
    }
}
