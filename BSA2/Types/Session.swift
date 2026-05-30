//
//	Session.swift
//  BSA2
//
//  Created by Dominik Stücheli on 12.03.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import Foundation
import SwiftData



@Model class Session {
	
	var name: String
	var timestamp: Date
	
	//Content
	@Relationship(deleteRule: .cascade) var students: [Student]
	@Relationship(deleteRule: .cascade) var categories: [Category]
	@Relationship(deleteRule: .cascade) var allocations: [Allocation] = []
	
	//Settings
	var choiceAmount: Int = 3
	var allowForMandatoryPartners: Bool = true
	
	func studentTableRowCount() -> Int { if allowForMandatoryPartners { return choiceAmount+2 } else { return choiceAmount+1 } }
	
	init(_ name: String = "neue Zuteilung") {
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
