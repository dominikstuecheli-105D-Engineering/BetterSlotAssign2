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
