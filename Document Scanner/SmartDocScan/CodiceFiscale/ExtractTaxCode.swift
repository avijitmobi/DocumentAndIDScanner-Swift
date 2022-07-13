//
//  ExtractTaxCode.swift
//  Document Scanner
//
//  Created by Avijit Babu on 23/04/20.
//  Inspired from Luigi Aiello
//

import Foundation

public class FiscalCode: NSObject {
    public var name: String?
    public var surname: String?
    public var gender: Gender?
    public var date: Date?
    public var town: String?
    public var province: String?
    
    public init(name: String?, surname: String?, gender: Gender?, date: Date?, town: String?, province: String?) {
        self.name = name
        self.surname = surname
        self.gender = gender
        self.date = date
        self.town = town
        self.province = province
    }
}

public class LocalAuthority: NSObject, Decodable {
    public var province: String
    public var town: String
    public var code: String
}

public enum Gender : String {
    case male = "M"
    case female = "F"
}

public class FiscalCodeManager: NSObject {
    
    // MARK: - Varibles
    public var localAuthorites: [LocalAuthority]?
    private let vowels = CharacterSet(charactersIn: "aeiou")
    private let monthCodes = "XABCDEHLMPRST"
    private let charactersLimit: Int = 3
    
    // MARK: - Init
    public override init() {
        localAuthorites = JSONSerializer.serializeFromPODFileJSON(modelType: [LocalAuthority].self, input: "LocalAuthorites", type: "json")
    }
    
    public init(localAuthorietsFileName fileName: String, localAuthorietsExtension fileExtension: String) {
        localAuthorites = JSONSerializer.serializeFromFileJSON(modelType: [LocalAuthority].self, input: fileName, type: fileExtension)
    }
    
    public init(localAuthoriets: [LocalAuthority]) {
        localAuthorites = localAuthoriets
    }
    
    
    public func retriveInformationFrom(fiscalCode: String) -> FiscalCode? {
        guard fiscalCode.isValidFiscalCode else {
            return nil
        }
        let surname = fiscalCode[0..<3]
        let name = fiscalCode[3..<6]
        let year = fiscalCode[6..<8]
        let month = fiscalCode[8]
        let day = fiscalCode[9..<11]
        let cityCode = fiscalCode[11..<15]
        let gender = getGender(day)
        let date = getNormalizedDate(year: year, month: month, day: day, gender: gender ?? Gender.male)
        let localAuthority = findCityBy(cityCode)
        return FiscalCode(name: name,
                          surname: surname,
                          gender: gender,
                          date: date,
                          town: localAuthority?.town,
                          province: localAuthority?.province)
    }

    private func findCityCode(_ town: String) -> String? {
        guard let localAuthorites = self.localAuthorites else {
            return nil
        }
        
        let localAuthority = localAuthorites.first(where: { $0.town.lowercased() == town.lowercased() })
        
        return localAuthority?.code
    }
    
    /**
     Codice di controllo
     https://it.wikipedia.org/wiki/Codice_fiscale
     */
    private func calculateCin(input: String) -> String? {
        guard
            let evens = JSONSerializer.serializeFromPODFileJSON(modelType: [String: Int].self, input: "Evens", type: "json"),
            let odds = JSONSerializer.serializeFromPODFileJSON(modelType: [String: Int].self, input: "Odds", type: "json")
            else {
                return nil
        }
        
        let ctrlChar = [0: "A", 1: "B", 2: "C", 3: "D", 4: "E", 5: "F", 6: "G", 7: "H", 8: "I", 9: "J", 10: "K", 11: "L", 12: "M", 13: "N", 14: "O", 15: "P", 16: "Q", 17: "R", 18: "S", 19: "T", 20: "U", 21: "V", 22: "W", 23: "X", 24: "Y", 25: "Z"]
        
        var sumEvens = 0
        var sumOdds = 0
        
        var evensCharacters = String()
        var oddsCharacaters = String()
        
        for (index, character) in input.enumerated() {
            if (index + 1) % 2 == 0 {
                evensCharacters.append(character)
                sumEvens += evens[String(character)] ?? 0
            } else {
                oddsCharacaters.append(character)
                sumOdds += odds[String(character)] ?? 0
            }
        }
        
        return ctrlChar[(sumEvens + sumOdds) % 26]
    }
    
    // MARK: - Reverse
    private func findCityBy( _ code: String) -> LocalAuthority? {
        guard let localAuthorites = self.localAuthorites else {
            return nil
        }
        
        return localAuthorites.first(where: { $0.code == code })
    }
    
    private func getGender(_ day: String) -> Gender? {
        guard let intDay = Int(day) else {
            return nil
        }
        
        return intDay > 40 ? .female : .male
    }
    
    private func getNormalizedDate(year: String, month: Character, day: String, gender: Gender) -> Date? {
        guard
            var intDay = Int(day),
            var intYear = Int(year),
            let intMonth = monthCodes.firstIndex(of: month)
            else {
                return nil
        }
        
        let now = Date()
        let pos = monthCodes.distance(from: monthCodes.startIndex, to: intMonth)
        
        // Calculate Days
        if gender == .female {
            intDay -= 40
        }
        
        intYear += (now.component(.year) > intYear + 2000) ? 2000 : 1900
        
        let dayFormat = intDay > 9 ? "dd" : "d"
        let monthFormat = pos > 9 ? "MM" : "M"
        let yearFormat = "yyyy"
        
        return Date.from(string: "\(intDay) \(pos) \(intYear)", withFormat: "\(dayFormat) \(monthFormat) \(yearFormat)")
    }
    
    // MARK: - Helpers
    private func removeDirt(input: String) -> String {
        let dirtRemoved = input
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()
            .folding(options: .diacriticInsensitive, locale: .current)
        
        return dirtRemoved
    }
    
    private func divedeConsonantsAndVowels(input: String) -> (consonants: String, vowels: String) {
        var vowelsCharacters = String()
        var consonantsCharacters = String()
        
        for char in input {
            if String(char).rangeOfCharacter(from: vowels) != nil {
                vowelsCharacters.append(char)
            } else {
                consonantsCharacters.append(char)
            }
        }
        
        return (consonantsCharacters, vowelsCharacters)
    }
}


extension Date {
    static func from(string: String, withFormat format: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = format
        return dateFormatter.date(from: string)
    }
    
    func formatted(_ format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
    
    func components(_ calendarUnits: [Calendar.Component]) -> [Calendar.Component: Int] {
        var result: [Calendar.Component: Int] = [: ]
        for unit in calendarUnits {
            result[unit] = component(unit)
        }
        return result
    }
    
    func component(_ calendarUnit: Calendar.Component) -> Int {
        return Calendar.current.component(calendarUnit, from: self)
    }
}

internal extension Calendar.Component {
    func value(fromDate date: Date) -> Int {
        return date.component(self)
    }
}

extension String {
    subscript(_ range: CountableRange<Int>) -> String {
        let idx1 = index(startIndex, offsetBy: max(0, range.lowerBound))
        let idx2 = index(startIndex, offsetBy: min(self.count, range.upperBound))
        return String(self[idx1..<idx2])
    }
    
    subscript (position: Int) -> Character {
        return self[index(startIndex, offsetBy: position)]
    }
    
    var isValidFiscalCode: Bool {
        guard
            self.count > 0,
            self.count == 16
            else {
                return false
        }
        
        let pattern = "^[A-Z]{6}[A-Z0-9]{2}[A-Z][A-Z0-9]{2}[A-Z][A-Z0-9]{3}[A-Z]$"
        do {
            if try NSRegularExpression(pattern: pattern, options: .caseInsensitive).firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.count)) == nil {
                return false
            }
        } catch {
            return false
        }
        
        return true
    }
}


class JSONSerializer {
    static func serializeFromFileJSON<T>(modelType: T.Type, input sourceName: String, type: String) -> T? where T: Decodable {
        guard let path = Bundle.main.path(forResource: sourceName, ofType: type) else {
            assertionFailure("I didn't found any files with this name: \(sourceName).\(type)")
            return nil
        }
        
        return serialiFromFile(modelType: modelType, path: path)
    }
    
    static func serializeFromPODFileJSON<T>(modelType: T.Type, input sourceName: String, type: String) -> T? where T: Decodable {
        let podBundle = Bundle(for: JSONSerializer.self)
        
        guard let path = podBundle.path(forResource: sourceName, ofType: type) else {
            return nil
        }
        
        return serialiFromFile(modelType: modelType, path: path)
    }
    
    static func serialize<T>(modelType: T.Type, data: Data?) -> T? where T: Decodable {
        let jsonDecoder = JSONDecoder()
        var result: T?
        
        do {
            guard let data = data else {
                return nil
            }
            
            result = try jsonDecoder.decode(modelType, from: data)
        } catch let error {
            print(error)
        }
        
        return result
    }
    
    // MARK: - Private methods
    private static func serialiFromFile<T>(modelType: T.Type, path: String) -> T? where T: Decodable {
        let url = URL(fileURLWithPath: path)
        var result: T?
        
        do {
            let data = try Data(contentsOf: url)
            result = serialize(modelType: modelType, data: data)
        } catch let error {
            print("Error: \(error)")
        }
        
        return result
    }
}
