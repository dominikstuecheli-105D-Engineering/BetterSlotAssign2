//
//	AllocatedCategory.swift
//  BSA2
//
//  Created by Dominik Stücheli on 18.03.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import Foundation
import SwiftData



@Model class AllocatedCategory: PersistentArrayCompatible, CSVBlockEncodable {
	
	var name: String
	var index: Int
	
	var capacity: Int
	var minParticipants: Int
	
	@Relationship(deleteRule: .cascade) var students: [AllocatedStudent]
	
	var id = UUID()

	init?(from category: Category) {
		self.name = category.name
		
		guard let index = category.number else {return nil}
		self.index = index
		
		guard let capacity = category.capacity else {return nil}
		self.capacity = capacity
		
		guard let minParticipants = category.minParticipantRequirement else {return nil}
		self.minParticipants = minParticipants
		
		self.students = []
	}
	
	func makeStringTable(configuration: [Int:Student.RowConfigurator]) -> [[String]] {
		return CSV.makeTableFromItems(students.indexSorted(), configuration: configuration, header: [
			["\(index)", name, "\(students.count) Schüler*innen", "Max: \(capacity)", "Min: \(minParticipants)"],
			[""]
		])
	}
}
