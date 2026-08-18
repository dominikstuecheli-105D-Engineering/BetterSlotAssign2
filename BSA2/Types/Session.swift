//
//	Session.swift
//  BSA2
//
//  Created by Dominik Stücheli on 12.03.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import Foundation
import SwiftData



@Model final class Session {
	
	var name: String
	var timestamp: Date
	
	//Content
	@Relationship(deleteRule: .cascade) var students: [Student]
	@Relationship(deleteRule: .cascade) var categories: [Category]
	@Relationship(deleteRule: .cascade) var allocations: [Allocation] = []
	
	//Settings
	var choiceAmount: Int = 3
	var allowForMandatoryPartners: Bool = true
	
	var useGenderField: Bool = false
	var useGroupField: Bool = false
	var useProfileField: Bool = false
	
	//Table measurements
	@Transient var studentTableFirstChoiceRowIndex: Int {
		var v: Int = 2
		if useGenderField { v += 1 }
		if useGroupField { v += 1 }
		if useProfileField { v += 1 }
		return v
	}
	
	@Transient var studentTableRowCount: Int {
		var v: Int = studentTableFirstChoiceRowIndex-1
		v += choiceAmount
		if allowForMandatoryPartners { v += 1 }
		return v
	}
	
	//Cache
	@Transient private var studentsByName: [String:Student] = [:]
	
	fileprivate func tryToMakeEntryForStudentsByNameDict(for name: String) {
		if let student = students.first(where: {$0.name == name}) { studentsByName[name] = student }
	}
	
	func getStudentByName(_ name: String) -> Student? {
		foundProcess: if let found = studentsByName[name] {
			if found.name != name {
				studentsByName[name] = nil
				break foundProcess
			} else {return found}
		}
		
		tryToMakeEntryForStudentsByNameDict(for: name)
		return studentsByName[name]
	}
	
	//Initialiser
	init(_ name: String = "neue Sitzung") {
		let student = Student("", choices: [1:nil, 2:nil, 3:nil], index: 1)
		let category = Category(index: 1)
		
		self.students = [student]
		self.categories = [category]
		
		self.name = name
		self.timestamp = .now
	}
}



//Import from string arrays (from the CSV parser)
extension Session {
	
	func importStudents(fromStringArray stringTable: [[String]], configuration: [Int:Student.RowConfigurator], overrideExisting: Bool, from modelContext: ModelContext) {
		
		//If everything thats already there should be replaced
		if overrideExisting {
			for student in self.students {students.remove(student, from: modelContext)}
		}
		
		//Converting the string arrays to actual Student objects and adding them to the list
		let newStudents: [Student] = CSV.parseToItems(stringTable, configuration: configuration)
		newStudents.addToModelContext(modelContext)
		students.add(newStudents)
	}
	
	func importCategories(fromStringArray stringTable: [[String]], configuration: [Int:Category.RowConfigurator], overrideExisting: Bool, from modelContext: ModelContext) {
		
		//If everything thats already there should be replaced
		if overrideExisting {
			for category in self.categories {categories.remove(category, from: modelContext)}
		}
		
		//Converting the string arrays to actual Category objects and adding them to the list
		let newCategories: [Category] = CSV.parseToItems(stringTable, configuration: configuration)
		newCategories.addToModelContext(modelContext)
		categories.add(newCategories)
	}
	
}
