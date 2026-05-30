//
//	Category.swift
//  BSA2
//
//  Created by Dominik Stücheli on 12.03.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import Foundation
import SwiftData



@Model class Category: PersistentArrayCompatible, CSVCodable {
	
	var name: String
	var number: Int?
	
	var capacity: Int? = nil
	var minParticipantRequirement: Int? = nil
	
	var index: Int
	var id = UUID()
	
	init(_ name: String = "", number: Int? = nil, index: Int) {
		self.name = name
		self.number = number
		self.index = index
		self.id = UUID()
	}
	
	//Data transfer object
	struct DTO: Codable {
		var name: String
		var number: Int?
		var capacity: Int
		var minParticipantRequirement: Int?
		var index: Int
		var id: UUID
	}
	
	//Function to import from CSV formatted as string array
	required init?(fromStringArray strings: [String], configuration: [Int:RowConfigurator], index: Int) {
		guard strings.count >= configuration.count else {return nil}
		
		if let nameIndex = configuration.first(where: {$1 == .name}) {
			self.name = strings[nameIndex.key]
		} else {
			self.name = ""
		}
		
		if let numberIndex = configuration.first(where: {$1 == .number}) {
			if let integer = Int(strings[numberIndex.key]) {
				self.number = integer
			}
		} else {
			self.number = nil
		}
		
		if let capacityIndex = configuration.first(where: {$1 == .capacity}) {
			if let integer = Int(strings[capacityIndex.key]) {
				self.capacity = integer
			}
		} else {
			self.capacity = nil
		}
		
		if let minParticipantIndex = configuration.first(where: {$1 == .minMemberCount}) {
			if let integer = Int(strings[minParticipantIndex.key]) {
				self.minParticipantRequirement = integer
			}
		} else {
			self.minParticipantRequirement = nil
		}
		
		self.index = index
	}
	
	//Function to export to string array
	func makeStringArray(configuration: [Int:RowConfigurator]) -> [String] {
		return CSV.mapContent(configuration: configuration, disregardCase: .disregarded, contentMap: [
			.name: name,
			.number: "\(number, default: "")",
			.capacity: "\(capacity, default: "")",
			.minMemberCount: "\(minParticipantRequirement, default: "")"
		])
	}
	
	enum RowConfigurator {
		case disregarded
		case name
		case number
		case capacity
		case minMemberCount
		
		static func standartConfiguration(rowCount: Int) -> [Int:RowConfigurator] {
			var result: [Int:RowConfigurator] = [
				0: .name,
				1: .number,
				2: .capacity,
				3: .minMemberCount
			]
			if rowCount > 4 { for i in 1...rowCount-4 {
				result[i+3] = .disregarded
			} }
			return result
		}
	}
}
