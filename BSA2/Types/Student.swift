//
//	Student.swift
//  BSA2
//
//  Created by Dominik Stücheli on 12.03.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import Foundation
import SwiftData



@Model final class Student: PersistentArrayCompatible, CSVCodable, LUAObjectCodable, SearchTokenProvider {
	
	var name: String
	
	var gender: String
	var group: String
	var profile: String
	
	var choices: [Int:Int?]
	var mandatoryPartner: String
	
	var index: Int
	var id = UUID()
	
	//Values for faster condition checking
	@Transient fileprivate var nameThatHasBeenFormatted: String = ""
	@Transient fileprivate var localFormattedName: String = ""
	@Transient var formattedName: String {
		if nameThatHasBeenFormatted != name {
			localFormattedName = name.simplify()
			nameThatHasBeenFormatted = name
		}
		return localFormattedName
	}
	
	//Initialiser
	init(_ name: String = "", choices: [Int:Int?] = [:], index: Int) {
		self.name = name
		self.gender = ""
		self.group = ""
		self.profile = ""
		self.choices = choices
		self.mandatoryPartner = ""
		self.index = index
	}
	
	//Search tokens
	@Transient var searchTokens: [SearchToken<RowConfigurator>] {
		return [
			.init(name, identifier: .name),
			.init(gender, identifier: .gender),
			.init(group, identifier: .group),
			.init(profile, identifier: .profile),
			.init(mandatoryPartner, identifier: .mandatoryPartner),
		]
	}
	
	@Transient var matchingTokensOnLastSearch: Set<TokenIdentifier> = []
	
	//Function to import from CSV formatted as string array
	required init?(fromStringArray strings: [String], configuration: [Int:RowConfigurator], index: Int) {
		guard strings.count >= configuration.count else {return nil}
		
		if let nameIndex = configuration.first(where: {$1 == .name}) {
			self.name = strings[nameIndex.key]
		} else { self.name = "" }
		
		if let genderIndex = configuration.first(where: {$1 == .gender}) {
			self.gender = strings[genderIndex.key]
		} else { self.gender = "" }
		
		if let groupIndex = configuration.first(where: {$1 == .group}) {
			self.group = strings[groupIndex.key]
		} else { self.group = "" }
		
		if let profileIndex = configuration.first(where: {$1 == .profile}) {
			self.profile = strings[profileIndex.key]
		} else { self.profile = "" }
		
		if let partnerIndex = configuration.first(where: {$1 == .mandatoryPartner}) {
			self.mandatoryPartner = strings[partnerIndex.key]
		} else { self.mandatoryPartner = "" }
		
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
	
	//Exporting LUA tables to give to the LUA happyness function
	func makeLUATable() -> LUATable {
		return [
			"name": name,
			"gender": gender,
			"group": group,
			"profile": profile,
			"choices": choices, ///Still a "dictionary", its just nested in the greater LUATable dictionary now
			"mandatoryPartner": mandatoryPartner,
		]
	}
	
	enum RowConfigurator {
		case disregarded
		case name
		case gender
		case group
		case profile
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
