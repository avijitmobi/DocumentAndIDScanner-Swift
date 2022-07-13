//
//  SDRCropError.swift
//  Smart Doc Recognizer
//
//  Inspired by Никита Разумный on 11/04/20.
//  Copyright © 2017 Avijit and Никита Разумный. All rights reserved.
//

import UIKit
//Crop error model croping image document
public enum SDRCropError: Error {
    case missingSuperview
    case missingImageOnImageView
    case invalidNumberOfCorners
    case nonConvexRect
    case missingImageWhileCropping
    case unknown
}
