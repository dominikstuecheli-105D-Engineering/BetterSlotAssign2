//
//	ErrorCollector.swift
//  BSA2
//
//  Created by Dominik Stücheli on 16.03.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import Foundation
import SwiftUI



enum ConditionReturn: Equatable {
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
	
	static func ==(lhs: ConditionReturn, rhs: ConditionReturn) -> Bool {
		return (lhs.getTypeString() == rhs.getTypeString() && lhs.getErrorText() == rhs.getErrorText())
	}
}



struct ErrorCollectorItemView: View {
	
	var value: ConditionReturn
	var focusIndex: Int
	var onClick: (Int) -> Void
	
	var body: some View {
		if let errorText = value.getErrorText() {
			HStack(spacing: standartPadding) {
				RoundedRectangle(cornerRadius: standartPadding/2)
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



@Observable class OLDErrorCollector {
	
	static var shared = OLDErrorCollector() //Singleton
	
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



//MARK: NOT USED YET
@Observable class ErrorCollector {
	
	static var shared = ErrorCollector() //Singleton
	
	var cellConditionHosts: [Int:any CellConditionHost] = [:]
	var errors: [Int:ConditionReturn] = [:]
	
	private var updateWorkItem: DispatchWorkItem?
	
	//Schedule an update
	static func scheduleUpdate(at index: Int) {
		self.shared.updateWorkItem?.cancel()
		
		self.shared.updateWorkItem = DispatchWorkItem {ErrorCollector.update(at: index)}
		DispatchQueue.main.asyncAfter(deadline: .now()+0.2, execute: self.shared.updateWorkItem!)
	}
	
	//Update state and trigger view updates of the given update group
	fileprivate static func update(at index: Int) {
		let oldUpdateGroup = self.shared.errors[index]?.getUpdateGroup() ?? [] //The old update group also needs to be updated to revert eventual changes
		
		let newState = self.shared.cellConditionHosts[index]!.update()
		
		///**IN CASE OF BUGS**
		//print("oldUpdateGroup: \(oldUpdateGroup)")
		//print("update initiated at \(index) with updateGroup: \(newState.getUpdateGroup() ?? [])")
		
		self.shared.errors[index] = newState
		
		var updateGroup: [Int] = []
		if let newUpdateGroup = newState.getUpdateGroup() {
			updateGroup = mergeUpdateGroups(oldUpdateGroup, newUpdateGroup)
		} else {
			updateGroup = oldUpdateGroup
		}
		
		//print("final updateGroup: \(updateGroup)")
		
		for updateIndex in updateGroup {
			if updateIndex != index { self.shared.errors[updateIndex] = self.shared.cellConditionHosts[updateIndex]!.update() }
		}
	}
	
	static func reset() {
		self.shared.updateWorkItem?.cancel()
		self.shared.cellConditionHosts = [:]
		self.shared.errors = [:]
	}
	
	static func readAndSaveAllCellStatesIntoErrorsArray() {
		for cellConditionHostDictPair in ErrorCollector.shared.cellConditionHosts {
			ErrorCollector.shared.errors[cellConditionHostDictPair.key] = cellConditionHostDictPair.value.state
		}
	}
	
	init() {}
}



protocol CellConditionHost {
	associatedtype SourceValueType
	associatedtype ConditionCheckValueType
	var getValueFunction: () -> SourceValueType {get}
	var updateFunction: (ConditionCheckValueType) -> ConditionReturn {get}
	var state: ConditionReturn {get}
	
	func update() -> ConditionReturn
	
	init(getValue getValueFunction: @escaping () -> SourceValueType, update updateFunction: @escaping (ConditionCheckValueType) -> ConditionReturn)
}



@Observable class TextCellConditionHost: CellConditionHost {
	
	internal var getValueFunction: () -> String
	internal var updateFunction: (String) -> ConditionReturn
	var state: ConditionReturn
	
	internal func update() -> ConditionReturn {
		state = updateFunction(getValueFunction())
		return state
	}
	
	required init(getValue getValueFunction: @escaping () -> String, update updateFunction: @escaping (String) -> ConditionReturn) {
		self.getValueFunction = getValueFunction
		self.updateFunction = updateFunction
		state = updateFunction(getValueFunction())
	}
}



@Observable class IntegerCellConditionHost: CellConditionHost {
	
	internal var getValueFunction: () -> Int?
	internal var updateFunction: (Int) -> ConditionReturn
	var state: ConditionReturn
	
	internal func update() -> ConditionReturn {
		let value = getValueFunction()
		if let integer: Int = value {
			state = updateFunction(integer)
			return state
		} else {
			state = .invalid(errorText: "Muss eine ganze Zahl sein")
			return state
		}
	}
	
	required init(getValue getValueFunction: @escaping () -> Int?, update updateFunction: @escaping (Int) -> ConditionReturn) {
		self.getValueFunction = getValueFunction
		self.updateFunction = updateFunction
		
		let value = getValueFunction()
		if let integer: Int = value {
			state = updateFunction(integer)
		} else {
			state = .invalid(errorText: "Muss eine ganze Zahl sein")
		}
	}
}
