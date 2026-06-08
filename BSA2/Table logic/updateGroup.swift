//
//	updateGroup functions.swift
//  BSA2
//
//  Created by Dominik Stücheli on 18.03.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import Foundation



//BASE UPDATE GROUP FUNCTIONS

///Update groups are arrays of CellIndices that specify which other cells need to check their conditions too after the user edited a cell. The functions here help create these update groups.

//Whole line
func updateGroup(line: Int, rowCount: Int) -> [CellIndex] {
	var output: [CellIndex] = []
	for rowIndex in 1...rowCount {output.append( CellIndex(line: line, row: rowIndex) )}
	return output
}

//Whole row
func updateGroup(row: Int, lineCount: Int) -> [CellIndex] {
	var output: [CellIndex] = []
	for line in 1...lineCount {output.append( CellIndex(line: line, row: row) )}
	return output
}

//An array of specific cells in the same line
func updateGroup(cells: [Int], line: Int) -> [CellIndex] {
	var output: [CellIndex] = []
	for cell in cells {output.append( CellIndex(line: line, row: cell) )}
	return output
}

//A specific amount of cells in a line starting at a specific cell
func updateGroup(startCell: Int, cellCount: Int, line: Int) -> [CellIndex] {
	var output: [CellIndex] = []
	for cell in 1...cellCount {output.append( CellIndex(line: line, row: cell + startCell-1) )}
	return output
}

//Merge update groups to avoid duplicate cell indices
func mergeUpdateGroups(_ group1: [CellIndex], _ group2: [CellIndex]) -> [CellIndex] {
	var output: [CellIndex] = group1
	for cell in group2 {
		if !group1.contains(where: {$0 == cell}) {output.append(cell)}
	}
	return output
}
