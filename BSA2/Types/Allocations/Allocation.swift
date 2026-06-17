//
//	Allocation.swift
//  BSA2
//
//  Created by Dominik Stücheli on 16.03.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import Foundation
import SwiftData



@Model class Allocation: PersistentArrayCompatible {
	
	//Content
	var name: String
	
	@Relationship(deleteRule: .cascade) var unAllocatedStudents: [AllocatedStudent] = []
	@Relationship(deleteRule: .cascade) var categories: [AllocatedCategory] = []
	@Relationship(deleteRule: .cascade) var documentation: [AllocationDocumentationEntry] = []
	
	//General settings
	var choiceAmount: Int
	var allowForMandatoryPartners: Bool
	
	var useGenderField: Bool
	var useGroupField: Bool
	var useProfileField: Bool
	
	//Generation settings
	var studentBalancing: Allocation.StudentBalancing = Allocation.StudentBalancing.deleteCategoriesWithNotEnoughMembers
	var happynessFunction: Allocation.HappynessFunction = Allocation.HappynessFunction.exponentialDivideSuffering
	var maxSearchDepth: Int
	var maxTime: TimeInterval = 5
	var allowDymanicTime: Bool = true
	var debugMode: Bool = false
	
	//Result data
	var happynessScore: Double = 0
	
	//Metadata
	var timestamp: Date
	var index: Int
	var id = UUID()
	
	var generationDuration: TimeInterval = 0
	
	///A string that provides all information about the configuration of an Allocation
	func propertyString() -> String {
		return "Glücklichkeits-score: \(happynessScore*100)% | Anzahl Wahlmöglichkeiten: \(choiceAmount) | Zwingende Partner*innen erlauben: \(allowForMandatoryPartners ? "Ja" : "Nein") | Zuteilungsmodus: \(studentBalancing.title()) | Glücklichkeitsfunktion: \(happynessFunction.title()) | Max. Suchtiefe: \(maxSearchDepth), Max, Laufzeit: \(String(format:"%.3f",maxTime))s | Zusätzliche Zeit erlauben: \(allowDymanicTime ? "Ja" : "Nein"), tatsächliche Zeit: \(String(format:"%.3f",generationDuration))s"
	}
	
	init(from session: Session, name: String) {
		self.index = session.allocations.nextIndex()
		self.timestamp = .now
		
		self.choiceAmount = session.choiceAmount
		self.allowForMandatoryPartners = session.allowForMandatoryPartners
		self.name = name
		
		self.useGenderField = session.useGenderField
		self.useGroupField = session.useGroupField
		self.useProfileField = session.useProfileField
		
		self.maxSearchDepth = 6
	}
	
	//Exporting
	func getExportableCSVTable() -> (table: [[String]], fileName: String) {
		var returnTable: [[String]] = []
		
		var rowCounter: Int = 1
		var configuration: [Int:Student.RowConfigurator] = [0: .name]
		
		if useGenderField { configuration[rowCounter] = .gender; rowCounter += 1 }
		if useGroupField { configuration[rowCounter] = .group; rowCounter += 1 }
		if useProfileField { configuration[rowCounter] = .profile; rowCounter += 1 }
		
		for _ in 1...choiceAmount {
			configuration[rowCounter] = .choice
			rowCounter += 1
		}
		
		if allowForMandatoryPartners { configuration[rowCounter] = .mandatoryPartner; rowCounter += 1 }
		
		for category in categories.indexSorted() {
			returnTable.append(contentsOf: category.makeStringTable(configuration: configuration))
			returnTable.append(["--------------------------------------------------------------"])
		}
		
		return (table: returnTable, fileName: name)
	}
}



extension Allocation {
	enum StudentBalancing: Codable {
		case deleteCategoriesWithNotEnoughMembers
		case tryToFillCategoriesWithNotEnoughMembers
		
		func title() -> String { switch self {
		case .deleteCategoriesWithNotEnoughMembers: return "Kategorien mit zu wenigen Teilnehmern löschen und Teilnehmer neu verteilen"
		case .tryToFillCategoriesWithNotEnoughMembers: return "Kategorien mit zu wenigen Teilnehmern versuchen zu füllen"
		} }
	}
	
	///The type of function used to calculate the happyness score
	enum HappynessFunction: Codable {
		case exponentialDivideSuffering
		case linear
		case exponentialConcentrateSuffering
		
		func title() -> String { switch self {
		case .exponentialDivideSuffering: return "Verteiltes Glück (Exponentiell, empfohlen)"
		case .linear: return "Verteiltes Glück (Linear)"
		case .exponentialConcentrateSuffering: return "Konzentriertes Glück (Nicht empfohlen)"
		} }
	}
	
	func findPartnerOf(_ student: AllocatedStudent, in category: AllocatedCategory?) -> AllocatedStudent? {
		if category == nil { return unAllocatedStudents.first(where: {$0.name == student.mandatoryPartnerName}) }
		if let category { return category.students.first(where: {$0.name == student.mandatoryPartnerName}) }
		return nil
	}
	
	
	
	///Special move function because it also needs to take into consideration the unAllocatedStudents array
	func moveStudentFromTransferable(to newCategoryIndex: Int, at toIndex: Int) {
		guard let student = ReferenceTransferable.reference as? AllocatedStudent else {return}
		guard let oldCategoryIndex = ReferenceTransferable.originInformation as? Int else {return}
		
		//Inside of unAllocatedStudents
		if oldCategoryIndex == 0 && newCategoryIndex == 0 { ///category index of 0 is the unAllocatedStudents array
			unAllocatedStudents.move(student, to: toIndex)
			
			if let partner = findPartnerOf(student, in: nil) {
				unAllocatedStudents.move(partner, to: toIndex+1)
			}
			
			return
		}
		
		//Inside of the same category
		if oldCategoryIndex == newCategoryIndex {
			guard let category = categories.first(where: {$0.index == oldCategoryIndex}) else {return}
			
			category.students.move(student, to: toIndex)
			
			if let partner = findPartnerOf(student, in: category) {
				category.students.move(partner, to: toIndex+1)
			}
			
			return
		}
		
		//Between two categories
		if oldCategoryIndex != 0 && newCategoryIndex != 0 {
			guard let oldCategory = categories.first(where: {$0.index == oldCategoryIndex}) else {return}
			guard let newCategory = categories.first(where: {$0.index == newCategoryIndex}) else {return}
			
			oldCategory.students.remove(student)
			newCategory.students.add(student, at: toIndex)
			
			if let partner = findPartnerOf(student, in: oldCategory) {
				oldCategory.students.remove(partner)
				newCategory.students.add(partner, at: toIndex+1)
			}
			
			ReferenceTransferable.originInformation = newCategoryIndex
			reCalculateHappynessScore()
			return
		}
		
		//If destination is unAllocatedStudents
		if newCategoryIndex == 0 {
			guard let category = categories.first(where: {$0.index == oldCategoryIndex}) else {return}
			
			category.students.remove(student)
			unAllocatedStudents.add(student, at: toIndex)
			
			if let partner = findPartnerOf(student, in: category) {
				category.students.remove(partner)
				unAllocatedStudents.add(partner, at: toIndex+1)
			}
			
			ReferenceTransferable.originInformation = 0
			reCalculateHappynessScore()
			return
		}
		
		//If origin is unAllocatedStudents
		if oldCategoryIndex == 0 {
			guard let category = categories.first(where: {$0.index == newCategoryIndex}) else {return}
			
			unAllocatedStudents.remove(student)
			category.students.add(student, at: toIndex)
			
			if let partner = findPartnerOf(student, in: nil) {
				unAllocatedStudents.remove(partner)
				category.students.add(partner, at: toIndex+1)
			}
			
			ReferenceTransferable.originInformation = newCategoryIndex
			reCalculateHappynessScore()
			return
		}
	}
	
	//Happyness score recalculation in case of manual changes
	func reCalculateHappynessScore() {
		var totalHappynessScore: Double = 0
		var studentCounter = 0
		
		for category in categories {
			for student in category.students {
				studentCounter += 1
				for choice in student.choices {
					if choice.value == category.index {
						totalHappynessScore += happynessScore(inChoice: choice.key)
						break
					}
				}
			}
		}
		
		studentCounter += unAllocatedStudents.count
		happynessScore = totalHappynessScore/Double(studentCounter)
	}
}
