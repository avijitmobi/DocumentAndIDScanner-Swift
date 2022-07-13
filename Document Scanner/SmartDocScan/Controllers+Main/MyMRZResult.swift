//
//  MyMRZResult.swift
//  MyMRZParser
//
//  Created by Avijit Babu on 23/04/20.
//  Inspired from Matej
//

import Foundation
import UIKit

public struct MyMRZResult {
    
    public let documentType: String?
    public let countryCode: String?
    public let surnames: String?
    public let givenNames: String?
    public let documentNumber: String?
    public let nationalityCountryCode: String?
    public let birthdate: Date?
    public let sex: String?
    public let expiryDate: Date?
    public let personalNumber: String?
    public let personalNumber2: String?
    public let isDocumentNumberValid: Bool?
    public let isBirthdateValid: Bool?
    public let isExpiryDateValid: Bool?
    public let isPersonalNumberValid: Bool?
    public let allCheckDigitsValid: Bool?
    public var finalImage : UIImage?
    public var passportImage : UIImage?
    
}
