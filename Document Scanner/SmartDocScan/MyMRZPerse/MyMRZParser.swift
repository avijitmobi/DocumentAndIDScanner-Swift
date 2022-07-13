//
//  MyMRZParser.swift
//  MyMRZParser
//
//  Created by Avijit Babu on 23/04/20.
//  Inspired from Matej
//

import Foundation

public class MyMRZParser {
    let formatter: MyMRZFieldFormatter
    
    enum MRZFormat: Int {
        case td1, td2, td3, invalid
    }
    
    public init(ocrCorrection: Bool = false) {
        formatter = MyMRZFieldFormatter(ocrCorrection: ocrCorrection)
    }
    
    // MARK: Parsing
    public func parse(mrzLines: [String]) -> MyMRZResult? {
        let mrzFormat = self.mrzFormat(from: mrzLines)
        
        switch mrzFormat {
        case .td1:
            return TD1(from: mrzLines, using: formatter).result
        case .td2:
            return TD2(from: mrzLines, using: formatter).result
        case .td3:
            return TD3(from: mrzLines, using: formatter).result
        case .invalid:
            return nil
        }
    }
    
    public func parse(mrzString: String) -> MyMRZResult? {
        return parse(mrzLines: mrzString.components(separatedBy: "\n"))
    }
    
    // MARK: MRZ-Format detection
    fileprivate func mrzFormat(from mrzLines: [String]) -> MRZFormat {
        switch mrzLines.count {
        case 2:
            let lineLength = uniformedLineLength(for: mrzLines)
            let possibleFormats = [MRZFormat.td2: TD2.lineLength, .td3: TD3.lineLength]
            
            for (format, requiredLineLength) in possibleFormats where lineLength == requiredLineLength {
                return format
            }
            
            return .invalid
        case 3:
            return (uniformedLineLength(for: mrzLines) == TD1.lineLength) ? .td1 : .invalid
        default:
            return .invalid
        }
    }
    
    fileprivate func uniformedLineLength(for mrzLines: [String]) -> Int? {
        guard let lineLength = mrzLines.first?.count else {
            return nil
        }
        
        if mrzLines.contains(where: { $0.count != lineLength }) {
            return nil
        }
        
        return lineLength
    }
}
