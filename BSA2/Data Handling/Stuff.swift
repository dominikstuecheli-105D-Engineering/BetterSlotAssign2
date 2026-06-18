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

