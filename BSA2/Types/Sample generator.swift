//
//	Sample generator.swift
//  BSA2
//
//  Created by Dominik Stücheli on 07.04.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import Foundation
import SwiftData



func generateSimpleSampleSession(into modelContext: ModelContext, studentCount: Int, choiceAmount: Int) {
	
	let session = Session("Sample data (\(studentCount) @ \(choiceAmount))")
	session.students.removeAll()
	session.categories.removeAll()
	session.allowForMandatoryPartners = false
	session.choiceAmount = choiceAmount
	modelContext.insert(session)
	
	for i in 1...studentCount {
		let student = Student("Student \(i)", index: i)
		for k in 1...choiceAmount {student.choices[k] = k}
		modelContext.insert(student)
		session.students.addAtEnd(student)
	}
	
	for i in 1...choiceAmount {
		let category = Category("Category \(i)", number: i, index: i)
		category.capacity = Int((Double(studentCount)/Double(choiceAmount)).rounded(.up))
		category.minParticipantRequirement = 0
		session.categories.addAtEnd(category)
		modelContext.insert(category)
	}
}



func generateSimpleSampleSessionWithRandomizedChoices(into modelContext: ModelContext, studentCount: Int, choiceAmount: Int) {
	
	let session = Session("Sample data (Randomized choices, \(studentCount) @ \(choiceAmount))")
	session.students.removeAll()
	session.categories.removeAll()
	session.allowForMandatoryPartners = false
	session.choiceAmount = choiceAmount
	modelContext.insert(session)
	
	for i in 1...studentCount {
		let student = Student("Student \(i)", index: i)
		var alreadyChosenCategories: [Int] = []
		
		for k in 1...choiceAmount {
			var randomChoice = 0
			while randomChoice == 0 || alreadyChosenCategories.contains(randomChoice) {
				randomChoice = Int.random(in: 1...choiceAmount)
			}
			student.choices[k] = randomChoice
			alreadyChosenCategories.append(randomChoice)
		}
		modelContext.insert(student)
		session.students.addAtEnd(student)
	}
	
	for i in 1...choiceAmount {
		let category = Category("Category \(i)", number: i, index: i)
		category.capacity = Int((Double(studentCount)/Double(choiceAmount)).rounded(.up))
		category.minParticipantRequirement = 0
		session.categories.addAtEnd(category)
		modelContext.insert(category)
	}
}
