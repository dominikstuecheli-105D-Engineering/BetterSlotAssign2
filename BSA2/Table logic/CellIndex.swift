//
//	CellIndex.swift
//  BSA2
//
//  Created by Dominik Stücheli on 01.06.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import Foundation



//MARK: MAJOR BLUNDER REGARDING THE USE OF "ROW"
///**Throughout the entire Codebase, line and row are used to describe horizontal and vertical sections in a table respectively, even tho it would correctly be row and column. Im really sorry about that.**



//It may be a little less "fast", but much nicer to work with, rather than single-integer values as indices for cells in a table
nonisolated struct CellIndex: Hashable {
	
	var line: Int
	var row: Int
	
	init(line: Int, row: Int) {
		self.line = line
		self.row = row
	}
	
	mutating func increase(rowCount: Int) {
		row = row+1
		if row > rowCount { row = 1; line = line+1 }
	}
	
	//Comparing
	static func < (lhs: CellIndex, rhs: CellIndex) -> Bool {
		if lhs.line < rhs.line { return true }
		if lhs.line == rhs.line && lhs.row < rhs.row { return true }
		return false
	}
}



//has to be MainActor isolated because it accesses SwiftData models
@MainActor extension CellIndex {
	init(item: any PersistentArrayCompatible, row: Int) {
		self.line = item.index
		self.row = row
	}
}
