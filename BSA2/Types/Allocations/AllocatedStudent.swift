//
//	AllocatedStudent.swift
//  BSA2
//
//  Created by Dominik Stücheli on 18.03.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import Foundation
import SwiftData



@Model class AllocatedStudent: PersistentArrayCompatible, CSVEncodable {
	
	var name: String
	
	var gender: String
	var group: String
	var profile: String
	
	var choices: [Int:Int?]
	var mandatoryPartnerName: String ///Only the name is stored as a string, not an actual object reference since it isnt really needed.
	
	var index: Int
	var id = UUID()
	
	init(from student: Student, choiceAmount: Int) {
		self.name = student.name
		var choices = student.choices
		
		self.gender = student.gender
		self.group = student.group
		self.profile = student.profile
		
		for choice in choices {
			if choice.key > choiceAmount {
				choices[choice.key] = nil
			}
		}; self.choices = choices
		
		self.mandatoryPartnerName = student.mandatoryPartner
		self.index = student.index
	}
	
	init(from student: AllocatedStudentDummy) {
		self.name = student.name
		self.choices = student.choiceFromCategory
		self.gender = student.gender
		self.group = student.group
		self.profile = student.profile
		self.index = 1 ///Will be overwritten anyways because its added with .addAtEnd()
		self.mandatoryPartnerName = student.mandatoryPartner ?? ""
	}
	
	func makeStringArray(configuration: [Int:Student.RowConfigurator]) -> [String] {
		var choiceCounter = 0 ///Start at 0 because the counter is increased before the value is read from the dictionary
		
		return CSV.mapContent(configuration: configuration, disregardCase: .disregarded, contentMap: [
			.name: {return self.name},
			.gender: {return self.gender},
			.group: {return self.group},
			.profile: {return self.profile},
			.mandatoryPartner: {return self.mandatoryPartnerName},
			.choice: {choiceCounter += 1; return self.choices[choiceCounter].string()}
		])
	}
}
