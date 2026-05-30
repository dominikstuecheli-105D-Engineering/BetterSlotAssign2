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
		
		//This actually isnt really a requirement but its kinda bad with finished allocations because there cant be a name displayed
		guard name != "" else {return .invalid(errorText: "Es muss ein Name gegeben sein")}
		
		return .met()
	}
	
	//MARK: NUMBER
	func numberCondition(session: Session) -> ConditionReturn {
		
		//Same number as another category
		if let otherCategory = session.categories.first(where: {$0.number == number && $0.id != id}) {
			return .validButNotAllowed(errorText: "Es gibt bereits eine Kategorie mit dieser Nummer: \(otherCategory.name)", updateGroup: otherCategory.updateGroup(cell: 2))
		}
		
		return .met()
	}
	
	
}
