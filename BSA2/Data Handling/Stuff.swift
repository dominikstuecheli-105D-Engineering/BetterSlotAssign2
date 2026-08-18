//
//	Stuff.swift
//  BSA2
//
//  Created by Dominik Stücheli on 16.06.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import Foundation



extension Int {
	mutating func clamp(lower: Int, upper: Int) {
		if self < lower { self = lower } else
		if self > upper { self = upper }
	}
}



func isEven(_ value: Int) -> Bool {
	return !(value % 2 == 1)
}



//Easier handling of double optionals
extension Int?? {
	func string() -> String {
		let unwrapped: Int = (self ?? .max) ?? .max
		if unwrapped == .max {
			return ""
		} else {
			return "\(unwrapped)"
		}
	}
}



extension String {
	///Gets a specific character
	func char(at index: Int) -> Character? {
		guard index >= 0 && index <= self.count-1 else {return nil}
		let stringIndex = self.index(startIndex, offsetBy: index)
		return self[stringIndex]
	}
}



extension Array where Element == String.Element {
	///Gets a specific character
	func char(at index: Int) -> Character? {
		guard index >= 0 && index <= self.count-1 else {return nil}
		return self[index]
	}
}



extension Bundle {
	var appVersion: String {
		infoDictionary?["CFBundleShortVersionString"] as? String ?? "–"
	}
	
	var buildNumber: Int {
		guard let string = infoDictionary?["CFBundleVersion"] as? String, let build = Int(string) else {
			return 0
		}; return build
	}
}



func getBundleLUAScript(_ filename: String) -> String? {
	guard let url = Bundle.main.url(forResource: filename, withExtension: "lua") else {return nil}
	guard let code = try? String(contentsOf: url, encoding: .utf8) else {return nil}
	return code
}



extension CVarArg {
	func decimalPlaces(_ decimalPlaceCount: Int) -> String {
		return String(format: "%.\(decimalPlaceCount)f", self)
	}
}



fileprivate let germanLowercaseAccentsMap: [Character:String] = ["ä": "ae", "ö": "oe", "ü": "ue", "ß": "ss"]

extension String {
	///Removes capital and other special characters like diacratic ones to make comparing simpler
	func simplify() -> String {
		var newString = ""
		
		var characterIndexCounter: Int = 0
		var spaceCounter: Int = 0
		
		for character in self {
			characterIndexCounter += 1
			
			//Lowercase
			var revisedCharacter = character.lowercased()
			
			//Replace accents with non-german letters
			if let accentReplacement = germanLowercaseAccentsMap[character] { revisedCharacter = accentReplacement }
			
			//Spaces
			if character == " " {
				spaceCounter += 1
				if spaceCounter > 1 {revisedCharacter = ""} ///Replace multiple spaces with only one
				if characterIndexCounter == 1 || characterIndexCounter == self.count { revisedCharacter = "" } ///If the space is the first or last character, disregard
			} else { spaceCounter = 0 }
			
			//Remove diacratic stuff like ê -> e
			revisedCharacter = revisedCharacter.folding(options: .diacriticInsensitive, locale: nil)
			
			newString.append(revisedCharacter)
		}
		
		return newString
	}
}



protocol ViewForceUpdater {
	func forceViewUpdate()
}

extension PersistentArrayCompatible {
	func forceViewUpdate() {
		self.index = index
	}
}
