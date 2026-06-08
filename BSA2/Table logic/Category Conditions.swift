//
//	Category Conditions.swift
//  BSA2
//
//  Created by Dominik Stücheli on 09.04.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import Foundation



extension Category {
	
	//MARK: NAME
	func nameCondition(session: Session) -> ConditionReturn {
		
		//This actually isnt really a technical requirement but its kinda bad with finished allocations because there is no name displayed
		guard name != "" else {return .invalid(errorText: "Es muss ein Name gegeben sein")}
		
		return .met()
	}
	
	//MARK: NUMBER
	func numberCondition(session: Session) -> ConditionReturn {
		
		//Same number as another category
		if let otherCategory = session.categories.first(where: {$0.number == number && $0.id != id}) {
			return .validButNotAllowed(errorText: "Es gibt bereits eine Kategorie mit dieser Nummer: \(otherCategory.name)", updateGroup: [CellIndex(item: otherCategory, row: 2)])
		}
		
		return .met()
	}
	
}



@MainActor extension Session {
	///The function that provides the CellConditionHosts for every cell to the ErrorCollector
	func provideCellConditionHostsForCategoryTableToErrorCollector() { //Very compact function name I know
		ErrorCollector.setup({ [self] in
			var cellConditionHosts: [CellIndex:any CellConditionHost] = [:]
			
			for category in categories {
				cellConditionHosts[CellIndex(item: category, row: 1)] = TextCellConditionHost(getValue: {return category.name}, update: {_ in category.nameCondition(session: self)})
				
				cellConditionHosts[CellIndex(item: category, row: 2)] = IntegerCellConditionHost(getValue: {return category.number}, update: {_ in category.numberCondition(session: self)})
				
				cellConditionHosts[CellIndex(item: category, row: 3)] = IntegerCellConditionHost(getValue: {return category.capacity}, update: {_ in return .met()})
				
				cellConditionHosts[CellIndex(item: category, row: 4)] = IntegerCellConditionHost(getValue: {return category.minParticipantRequirement}, update: {_ in return .met()})
			}
			
			return cellConditionHosts
		})
	}
}
