//
//  SmartDocResult.swift
//  Smart Doc Recognizer
//
//  Created by Avijit Babu on 08/04/20.
//

import Foundation
import UIKit

public struct SmartDocResult {

	public let original: UIImage?
	public let cropped: UIImage?
    public let error : Error? = nil
	public let quad: RectangularSwap?

}
