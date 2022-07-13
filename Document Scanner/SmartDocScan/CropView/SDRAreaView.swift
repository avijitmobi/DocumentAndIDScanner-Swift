//
//  AreaView.swift
//  Smart Doc Recognizer
//
//  Inspired by Никита Разумный on 11/04/20.
//  Copyright © 2017 Avijit and Никита Разумный. All rights reserved.
//

import UIKit

//This class help you to draw the line of cropping image.
class SDRAreaView: UIView {

    var cropView : SDRCropView?
    var isPathValid = true
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentMode = .redraw
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        CATransaction.commit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        contentMode = .redraw
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        CATransaction.commit()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let path = cropView?.path else { return }
        
        let context = UIGraphicsGetCurrentContext()
        context?.setAllowsAntialiasing(true)
        context?.clip(to: rect)

        context?.addPath(path)
        context?.setLineWidth(2)
        context?.setLineCap(.round)
        context?.setLineJoin(.round)
        context?.setStrokeColor((isPathValid ? SDRCropView.goodAreaColor : SDRCropView.badAreaColor).cgColor)
        context?.strokePath()
        context?.saveGState()
        context?.addRect(bounds)
        context?.addPath(path)
        
        context?.setFillColor(UIColor(white: 0.3, alpha: 0.2).cgColor)
        context?.drawPath(using: .eoFill)
        
        context?.restoreGState()
    }
}
