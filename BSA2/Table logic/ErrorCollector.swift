//
//	ErrorCollector.swift
//  BSA2
//
//  Created by Dominik Stücheli on 16.03.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import Foundation
import SwiftUI



//The ConditionReturn type is what is returned by a function checking an input given in the table views. it gives information about what is wrong and what other values to check too (updateGroup)
enum ConditionReturn: Equatable {
	
	case invalid(errorText: String?) //The input is by type impossible
	case validButNotAllowed(errorText: String?, updateGroup: [CellIndex]) //The input has the right type but leads to conflicts with other data
	case conflictOfInterest(errorText: String?, updateGroup: [CellIndex]) //Same concept as validButNotAllowed but aiming to mark conflicts of interest
	case met(updateGroup: [CellIndex] = []) //The input is fully valid and doesnt conflict with other data
	
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
	
	func getUpdateGroup() -> [CellIndex]? {
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
	var focusIndex: CellIndex
	var onClick: (CellIndex) -> Void
	
	var body: some View {
		if let errorText = value.getErrorText() {
			HStack(spacing: standartPadding) {
				RoundedRectangle(cornerRadius: standartPadding/2)
					.frame(width: standartPadding)
					.foregroundStyle(value.getColor() ?? .gray)
				
				VStack {
					Text(value.getTypeString()) .font(.footnote) .foregroundStyle(.gray.opacity(0.6)) .fontWeight(.bold)
						.frame(maxWidth: .infinity, alignment: .leading)
					Text("(Zeile \(focusIndex.line), Spalte \(focusIndex.row))") .font(.footnote) .foregroundStyle(.gray.opacity(0.6))
						.frame(maxWidth: .infinity, alignment: .leading)
					Text(errorText)
						.frame(maxWidth: .infinity, alignment: .leading)
				}
			}
			.onTapGesture { onClick(focusIndex) }
		}
	}
}



//The ErrorCollector is a singleton that manages the states of all cells conditions, without the cells actually needing to be rendered by SwiftUI.
@Observable class ErrorCollector {
	
	static var shared = ErrorCollector() //Singleton
	
	var cellConditionHosts: [CellIndex:any CellConditionHost] = [:] ///The objects which can check the validity of an input in a cell
	var errors: [CellIndex:ConditionReturn] = [:] ///The dictionary which the cell views read from
	
	private var updateWorkItem: DispatchWorkItem?
	
	//Schedule an update
	///Prevents the computationally expensive checking of cell states from happening on every key press
	static func scheduleUpdate(at index: CellIndex) {
		self.shared.updateWorkItem?.cancel()
		self.shared.updateWorkItem = DispatchWorkItem {ErrorCollector.update(at: index)}
		DispatchQueue.main.asyncAfter(deadline: .now()+0.2, execute: self.shared.updateWorkItem!)
	}
	
	//Update the state of a specific cell and the given update group
	fileprivate static func update(at index: CellIndex) {
		guard let cellConditionHost = ErrorCollector.shared.cellConditionHosts[index] else {return}
		
		let oldUpdateGroup = self.shared.errors[index]?.getUpdateGroup() ?? [] //The old update group also needs to be updated to revert eventual changes
		
		let newState = cellConditionHost.update()
		self.shared.errors[index] = newState
		
		var updateGroup: [CellIndex] = []
		if let newUpdateGroup = newState.getUpdateGroup() {
			updateGroup = mergeUpdateGroups(oldUpdateGroup, newUpdateGroup)
		} else {
			updateGroup = oldUpdateGroup
		}
		
		///Because it would be very expensive to update every cell state on every change of any cell value, the updateGroup gives information about which cells may be effected by the change in the cell the user is changing the value of.
		for updateCellIndex in updateGroup {
			if updateCellIndex != index { self.shared.errors[updateCellIndex] = self.shared.cellConditionHosts[updateCellIndex]?.update() }
		}
	}
	
	private static func reset() {
		self.shared.updateWorkItem?.cancel()
		self.shared.cellConditionHosts = [:]
		self.shared.errors = [:]
	}
	
	private static func readAndSaveAllCellStatesIntoErrorsArray() {
		for cellConditionHostDictPair in ErrorCollector.shared.cellConditionHosts {
			ErrorCollector.shared.errors[cellConditionHostDictPair.key] = cellConditionHostDictPair.value.state
		}
	}
	
	static var setupProcessOngoing: Bool = false
	
	///The setup function wraps a closure that provides the cellConditionHosts in logic that prevents the closure from being called multiple times, because SwiftUI leads to this function possibly being called multiple times in one frame
	static func setup(_ setupFunction: @escaping () -> [CellIndex:any CellConditionHost]) {
		guard !setupProcessOngoing else {return}
		setupProcessOngoing = true
		
		DispatchQueue.main.async {
			reset()
			ErrorCollector.shared.cellConditionHosts = setupFunction()
			readAndSaveAllCellStatesIntoErrorsArray()
			setupProcessOngoing = false
		}
	}
	
	init() {}
}



//A CellConditionHost is an object that is created for every cell in a table, more or less seperate from SwiftUI view lifecycles. When creating a CellConditionHost, it has to be given a function that accesses the value of its cell and a function that checks the condition of that value. The updateFunction should only be checking the conditions of this one value and not of any other values.
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
	
	///For the Integer cell type the CellConditionHost already has the Integer check built in before the condition function (updateFunction) is called
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
