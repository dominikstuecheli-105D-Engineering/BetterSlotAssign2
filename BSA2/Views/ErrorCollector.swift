//
//	ErrorCollector.swift
//  BSA2
//
//  Created by Dominik Stücheli on 16.03.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import Foundation
import SwiftUI



enum ConditionReturn {
	case invalid(errorText: String?) //The input is by type impossible
	case validButNotAllowed(errorText: String?, updateGroup: [Int]) //The input has the right type but opens conflicts with other data
	case conflictOfInterest(errorText: String?, updateGroup: [Int]) //Same concept as validButNotAllowed but aiming to mark conflicts of interest
	case met(updateGroup: [Int] = []) //The input is fully valid and doesnt conflict with other data
	
	//The errorText is the debug text shown to the user that describes the error.
	//the update group is an array of all cell indices that are to be updated. this aims to reduce view building by directly adressing the cells that need to be updated. This is handled by the ErrorCollector below.

	func getErrorText() -> String? {
		switch self {
		case .invalid(let errorText): return errorText
		case .validButNotAllowed(let errorText, _): return errorText
		case .conflictOfInterest(errorText: let errorText, _): return errorText
		case .met(_): return nil
		}
	}
	
	func getTypeString() -> String {
		switch self {
		case .invalid(_): return "Ungültiger Typ"
		case .validButNotAllowed(_,_): return "Nicht erlaubte Eingabe"
		case .conflictOfInterest(_,_): return "Interessenkonflikt"
		case .met(_): return "Gegeben"
		}
	}
	
	func getColor() -> Color? {
		switch self {
		case .invalid(_): return .red
		case .validButNotAllowed(_,_): return .yellow
		case .conflictOfInterest(_,_): return .teal
		case .met(_): return nil
		}
	}
	
	func getUpdateGroup() -> [Int]? {
		switch self {
		case .invalid(_): return nil
		case .validButNotAllowed(_, let updateGroup): return updateGroup
		case .conflictOfInterest(_, let updateGroup): return updateGroup
		case .met(let updateGroup): return updateGroup
		}
	}
}



struct ErrorCollectorItemView: View {
	
	var value: ConditionReturn
	var focusIndex: Int
	var onClick: (Int) -> Void
	
	var body: some View {
		if let errorText = value.getErrorText() {
			HStack(spacing: standartPadding) {
				Rectangle()
					.frame(width: standartPadding)
					.foregroundStyle(value.getColor() ?? .gray)
				
				VStack {
					Text(value.getTypeString()) .font(.footnote) .foregroundStyle(.gray.opacity(0.6)) .fontWeight(.semibold)
						.frame(maxWidth: .infinity, alignment: .leading)
					Text(errorText)
						.frame(maxWidth: .infinity, alignment: .leading)
				}
			}
			.onTapGesture {
				onClick(focusIndex)
			}
		}
	}
}



@Observable class ErrorCollector {
	
	static var shared = ErrorCollector() //Singleton
	
	var errors: [Int:ConditionReturn] = [:]
	var updateTriggers: [Int:Bool] = [:]
	
	//Update state and trigger view updates of the given update group
	static func update(at index: Int, _ newState: ConditionReturn) {
		///**IN CASE OF BUGS** print("update initiated at \(index) with updateGroup: \(newState.getUpdateGroup() ?? [])")
		var updateGroup = self.shared.errors[index]?.getUpdateGroup() ?? [] //The old update group also needs to be updated to revert eventual changes
		
		if self.shared.updateTriggers[index] == nil {self.shared.updateTriggers[index] = false}
		
		self.shared.errors[index] = newState
		
		if let newUpdateGroup = newState.getUpdateGroup() {
			updateGroup = mergeUpdateGroups(updateGroup, newUpdateGroup)
		}
		
		for updateIndex in updateGroup {
			if updateIndex != index {self.shared.updateTriggers[updateIndex]?.toggle()}
		}
	}
	
	//Silent update function that itself does not trigger view updates of other cells because it would trigger an infinite loop if it would
	static func silentUpdate(at index: Int, _ newState: ConditionReturn) {
		if self.shared.updateTriggers[index] == nil {self.shared.updateTriggers[index] = false}
		self.shared.errors[index] = newState
	}
	
	//Remove the error and the update trigger
	static func discard(at index: Int) {
		self.shared.updateTriggers[index] = nil
		self.shared.errors[index] = nil
	}
	
	static func discardAll() {
		self.shared.updateTriggers = [:]
		self.shared.errors = [:]
	}
	
	init() {}
}
