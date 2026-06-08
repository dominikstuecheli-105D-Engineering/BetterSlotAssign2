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
	var choices: [Int:Int?]
	
	var mandatoryPartnerName: String ///Only the name is stored as a string, not an actual object reference since it isnt really needed.
	
	var index: Int
	var id = UUID()
	
	init(from student: Student, choiceAmount: Int) {
		self.name = student.name
		var choices = student.choices
		
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
		self.choices = student.categoryFromChoice
		self.id = student.id
		self.index = 1 //Will be overwritten anyways
		self.mandatoryPartnerName = student.mandatoryPartner ?? ""
	}
	
	func makeStringArray(configuration: [Int:Student.RowConfigurator]) -> [String] {
		var choiceCounter = 1
		
		return CSV.mapContent(configuration: configuration, disregardCase: .disregarded, contentMap: [
			.name: {return self.name},
			.mandatoryPartner: {return self.mandatoryPartnerName},
			.choice: {choiceCounter += 1; return self.choices[choiceCounter].string()}
		])
	}
}
