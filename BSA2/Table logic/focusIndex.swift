//
//	focusIndex.swift
//  BSA2
//
//  Created by Dominik Stücheli on 18.03.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import Foundation



func focusIndex(line: Int, row: Int, rowCount: Int) -> Int {
	return line * rowCount - rowCount + row
}

func focusIndex(item: any PersistentArrayCompatible, row: Int, rowCount: Int) -> Int {
	return item.index * rowCount - rowCount + row
}

func lineIndexFromFocusIndex(focusIndex: Int, rowCount: Int) -> Int {
	let inLineIndex = (focusIndex-1) % rowCount + 1
	let firstCellInLineIndex = focusIndex - inLineIndex
	return firstCellInLineIndex/rowCount + 1
}
