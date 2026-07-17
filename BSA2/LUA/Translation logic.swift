//
//	Translation logic.swift
//  BSA2
//
//  Created by Dominik Stücheli on 14.07.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import Foundation



typealias LUATable = [String:Any]

protocol LUAObjectCodable {
	func makeLUATable() -> LUATable
}
