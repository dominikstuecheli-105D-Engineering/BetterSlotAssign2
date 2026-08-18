//
//	HappynessFunction.swift
//  BSA2
//
//  Created by Dominik Stücheli on 14.07.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import Foundation
import SwiftData
import Lua



@Model final class HappynessFunction: Identifiable {
	
	var name: String
	var desc: String
	
	var code: String
	
	var id = UUID()
	var timestamp: Date
	
	var sourceLink: String? //If this value is nil, the happyness function is not bound to an external source. If it contains a link, the happyness function should not be editable as it is really a copy of an external source. This functionality is used mainly for the preset happyness functions.
	@Transient var isLocked: Bool { return sourceLink != nil }
	var updateFromSourceStatus: String = "N/A"
	
	//Function test inputs
	var testStudents: [Student] = []
	var testChoiceAmount: Int = 3
	
	//executing LUA code
	@Transient var lastExecutionTime: TimeInterval = 0
	@Transient var luaState: LuaState? = LuaState(libraries: .all)
	
	func openLuaState() throws {
		if luaState == nil {luaState = LuaState(libraries: .all)}
		try luaState!.dostring(code)
	}
	
	func closeLuaState() {
		luaState?.close()
		luaState = nil
	}
	
	func execute(student: Student, inChoice: Int, choiceAmount: Int, openLuaState openState: Bool = true, closeLuaState closeState: Bool = true) throws -> Double {
		do {
			let startTime: Date = .now
			
			if openState {try openLuaState()}
			
			///Trying to call the specific happynessFunction inside the LUA state global variables
			let returnValue: LuaValue = try luaState!.globals["happynessFunction"](student.makeLUATable(), inChoice, choiceAmount)
			lastExecutionTime = startTime.timeIntervalSinceNow
			
			guard returnValue.type == .number else {
				throw LuaCallError("Der zurückgegebene Wert ist keine Zahl sondern: \(returnValue.type)")
			}
			
			guard let double: Double = returnValue.tovalue() else {
				throw LuaCallError("Der zurückgegebene Wert kann nicht als Double ausgelesen werden")
			}
			
			if closeState {closeLuaState()}
			return double
			
		} catch {
			///If any error occured, close and clean the LUA state before rethrowing the error
			closeLuaState()
			throw error
		}
	}
	
	//Initialisers
	init(name: String) {
		self.name = name
		self.desc = ""
		self.code = getBundleLUAScript("happynessFunction Preset") ?? ""
		self.timestamp = .now
	}
	
	init(name: String, desc: String, code: String?) {
		self.name = name
		self.desc = desc
		self.code = code ?? ""
		self.timestamp = .now
	}
	
	init(from downloadData: HappynessFunctionDownloadData, code: String) {
		self.name = downloadData.niceTitle
		self.desc = downloadData.desc
		self.code = code
		self.timestamp = .now
		self.sourceLink = downloadData.url //Already lock it because it is from an external source
	}
}



//Because it is unsafe to store a reference to a HappynessFunction for an allocation in case that HappynessFunction is deleted, this snapshot captures all information needed by the allocation
@Model class HappynessFunctionSnapshot {
	
	var name: String
	var desc: String
	
	var id = UUID()
	var referencedHappynessFunctionId: UUID
	
	init(_ happynessFunction: HappynessFunction) {
		self.name = happynessFunction.name
		self.desc = happynessFunction.desc
		self.referencedHappynessFunctionId = happynessFunction.id
	}
	
}
