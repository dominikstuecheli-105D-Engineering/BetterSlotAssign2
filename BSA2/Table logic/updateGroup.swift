//
//	updateGroup functions.swift
//  BSA2
//
//  Created by Dominik Stücheli on 18.03.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import Foundation



//BASE UPDATE GROUP FUNCTIONS

//Whole line
func updateGroup(line: Int, rowCount: Int) -> [Int] {
	var output: [Int] = []
	for cellIndex in 1...rowCount {output.append( (line-1)*rowCount + cellIndex )}
	return output
}

//Whole row
func updateGroup(row: Int, rowCount: Int, lineCount: Int) -> [Int] {
	var output: [Int] = []
	for line in 1...lineCount {output.append( row + (line-1)*rowCount )}
	return output
}

//Specific cell
func updateGroup(cell: Int, line: Int, rowCount: Int) -> [Int] {
	return [(line-1)*rowCount + cell]
}

//An array of specific cells in the same line
func updateGroup(cells: [Int], line: Int, rowCount: Int) -> [Int] {
	var output: [Int] = []
	for cell in cells {output.append( (line-1)*rowCount + cell )}
	return output
}

//A specific amount of cells starting at a specific cell
func updateGroup(startCell: Int, cellCount: Int, line: Int, rowCount: Int) -> [Int] {
	var output: [Int] = []
	for cell in 1...cellCount {output.append( (line-1)*rowCount + startCell-1 + cell )}
	return output
}

//Merge update groups to avoid duplicate cell indices
func mergeUpdateGroups(_ group1: [Int], _ group2: [Int]) -> [Int] {
	var output: [Int] = group1
	for cell in group2 {
		if !group1.contains(where: {$0 == cell}) {output.append(cell)}
	}
	return output
}



//WRAPPERS WITH SESSION INPUT TO DETERMINE STUDENT TABLE SIZE

//Whole line
func studentUpdateGroup(line: Int, session: Session) -> [Int] {
	return updateGroup(line: line, rowCount: session.studentTableRowCount())
}

//Whole row
func studentUpdateGroup(row: Int, session: Session) -> [Int] {
	return updateGroup(row: row, rowCount: session.studentTableRowCount(), lineCount: session.students.count)
}

//Specific cell
func studentUpdateGroup(cell: Int, line: Int, session: Session) -> [Int] {
	return updateGroup(cell: cell, line: line, rowCount: session.studentTableRowCount())
}

//An array of specific cells in the same line
func studentUpdateGroup(cells: [Int], line: Int, session: Session) -> [Int] {
	return updateGroup(cells: cells, line: line, rowCount: session.studentTableRowCount())
}

//A specific amount of cells starting at a specific cell
func studentUpdateGroup(startCell: Int, cellCount: Int, line: Int, session: Session) -> [Int] {
	return updateGroup(startCell: startCell, cellCount: cellCount, line: line, rowCount: session.studentTableRowCount())
}

//Directly from student to get even less inputs
extension Student {
	//Whole line
	func updateGroup(session: Session) -> [Int] {
		return BSA2.updateGroup(line: self.index, rowCount: session.studentTableRowCount())
	}
	
	//Specific cell
	func updateGroup(cell: Int, session: Session) -> [Int] {
		return BSA2.updateGroup(cell: cell, line: self.index, rowCount: session.studentTableRowCount())
	}

	//An array of specific cells in the same line
	func studentUpdateGroup(cells: [Int], session: Session) -> [Int] {
		return BSA2.updateGroup(cells: cells, line: self.index, rowCount: session.studentTableRowCount())
	}

	//A specific amount of cells starting at a specific cell
	func studentUpdateGroup(startCell: Int, cellCount: Int, session: Session) -> [Int] {
		return BSA2.updateGroup(startCell: startCell, cellCount: cellCount, line: self.index, rowCount: session.studentTableRowCount())
	}
}



//WRAPPPERS DIRECTLY FROM CATEGORY

private let categoryTableRowCount: Int = 4

extension Category {
	//Whole line
	func updateGroup() -> [Int] {
		return BSA2.updateGroup(line: self.index, rowCount: categoryTableRowCount)
	}

	//Specific cell
	func updateGroup(cell: Int) -> [Int] {
		return BSA2.updateGroup(cell: cell, line: self.index, rowCount: categoryTableRowCount)
	}

	//An array of specific cells in the same line
	func updateGroup(cells: [Int]) -> [Int] {
		return BSA2.updateGroup(cells: cells, line: self.index, rowCount: categoryTableRowCount)
	}

	//A specific amount of cells starting at a specific cell
	func updateGroup(startCell: Int, cellCount: Int) -> [Int] {
		return BSA2.updateGroup(startCell: startCell, cellCount: cellCount, line: self.index, rowCount: categoryTableRowCount)
	}
}
