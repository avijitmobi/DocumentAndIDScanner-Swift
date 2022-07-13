//
//  Observation.swift
//  Smart Doc Recognizer
//
//  Created by Avijit Babu on 08/04/20.
//

import CoreImage

public struct Observation {

    public init(quad: RectangularSwap?, buffer: CVPixelBuffer) {
        self.quad = quad
        self.buffer = buffer
    }

	public let quad: RectangularSwap?
	public let buffer: CVPixelBuffer

}
