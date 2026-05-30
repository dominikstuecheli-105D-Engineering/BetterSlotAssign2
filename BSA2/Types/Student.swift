//
//	Student.swift
//  BSA2
//
//  Created by Dominik Stücheli on 12.03.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import Foundation
import SwiftData



@Model class Student: PersistentArrayCompatible, CSVCodable {
	
	var name: String
	var choices: [Int:Int?]
	var mandatoryPartner: String
	
	var index: Int
	var id = UUID()
	
	init(_ name: String = "", choices: [Int:Int?] = [:], index: Int) {
		self.name = name
		self.choices = choices
		self.mandatoryPartner = ""
		self.index = index
	}
	
	//Data transfer object
	struct DTO: Codable {
		var name: String
		var choices: [Int:Int?]
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
		
		if let partnerIndex = configuration.first(where: {$1 == .mandatoryPartner}) {
			self.mandatoryPartner = strings[partnerIndex.key]
		} else {
			self.mandatoryPartner = ""
		}
		
		self.index = index
		
		var choices: [Int:Int] = [:]
		var counter: Int = 1
		
		for choiceIndex in configuration.filter({$1 == .choice}) {
			if let integer = Int(strings[choiceIndex.key]) {
				choices[counter] = integer
				counter += 1
			}
		}
		
		self.choices = choices
	}
	
	//Function to export to string array
	func makeStringArray(configuration: [Int:RowConfigurator]) -> [String] {
		var choiceCounter = 1
		
		return CSV.mapContent(configuration: configuration, disregardCase: .disregarded, contentMap: [
			.name: {return self.name},
			.mandatoryPartner: {return self.mandatoryPartner},
			.choice: {choiceCounter += 1; return self.choices[choiceCounter].string()}
		])
	}
	
	enum RowConfigurator {
		case disregarded
		case name
		case choice
		case mandatoryPartner
		
		static func standartConfiguration(rowCount: Int) -> [Int:RowConfigurator] {
			var result: [Int:RowConfigurator] = [0: .name, rowCount-1: .mandatoryPartner]
			for i in 1...rowCount-2 {
				result[i] = .choice
			}
			return result
		}
	}
}



//Easier handling of double optionals
extension Int?? {
	func string() -> String {
		let unwrapped: Int = (self ?? 9999) ?? 9999
		if unwrapped == 9999 {
			return ""
		} else {
			return "\(unwrapped)"
		}
	}
}
