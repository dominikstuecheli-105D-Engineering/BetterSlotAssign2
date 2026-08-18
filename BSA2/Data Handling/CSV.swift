//
//	CSV.swift
//  BSA2
//
//  Created by Dominik Stücheli on 17.03.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers



//MARK: EXPLANATION ROWCONFIGURATOR

///The RowConfigurator type allows mapping of content, so it should be an enum of all types of content cells that should/could be in the CSV. the Dictionary with an Integer as a key then says which content is in what row index **(starting at 0)**. used for both encoding and decoding.



//MARK: SINGLE LINE CODABILITY

protocol CSVEncodable {
	associatedtype RowConfigurator
	func makeStringArray(configuration: [Int:RowConfigurator]) -> [String] //Making a CSV line array from the object
}

protocol CSVDecodable {
	associatedtype RowConfigurator
	init?(fromStringArray: [String], configuration: [Int:RowConfigurator], index: Int) //Initialising the object from a CSV line array
}

protocol CSVCodable: CSVEncodable, CSVDecodable {}



//MARK: MULTI LINE (BLOCK) CODABILITY

protocol CSVBlockEncodable {
	associatedtype RowConfigurator
	func makeStringTable(configuration: [Int:RowConfigurator]) -> [[String]] //Making a CSV table from the object
}

protocol CSVBlockDecodable {
	associatedtype RowConfigurator
	init?(fromStringTable: [[String]], configuration: [Int:RowConfigurator], index: Int) //Initialising the object from a CSV table
}

protocol CSVBlockCodable: CSVBlockEncodable, CSVBlockDecodable {}



//A class that contains all functions used for CSV Data handling. not really needed as a class but nice as a structure and for the syntax
final class CSV {
	
	//For parsing settings
	@Observable final class InstructionSet {
		var encoding: String.Encoding = .utf8
		var seperator: Character = ";"
		var firstLine: Int = 1
		var firstRow: Int = 1
		var rowCount: Int = 5
		
		init() {}
		
		init(firstLine: Int, firstRow: Int, rowCount: Int) {
			self.firstLine = firstLine
			self.firstRow = firstRow
			self.rowCount = rowCount
		}
	}
	
	
	
	//MARK: PARSING
	
	//Parsing from CSV string to string array
	static func parse(_ inputString: String, instructionSet: CSV.InstructionSet) -> [[String]] {
		var string = inputString
		
		//Remove BOM if there
		if string.hasPrefix("\u{FEFF}") {string.removeFirst()}
		
		//Normalize line breaks to \n
		string = string.replacingOccurrences(of: "\r\n", with: "\n")
		string = string.replacingOccurrences(of: "\r", with: "\n")
		
		var result: [[String]] = []
		var currentLine: [String] = []
		var currentField: String = ""
		var inQuotes: Bool = false
		
		//Actual parsing
		for char in string {
			switch char {
			//Quotes: ignore everything else until ended
			case "\"": inQuotes.toggle()
			
			//Line breaks: move to next line
			case "\n" where !inQuotes:
				currentLine.append(currentField)
				result.append(currentLine)
				currentLine = []
				currentField = ""
			
			//Seperator: move to next field
			case instructionSet.seperator where !inQuotes:
				currentLine.append(currentField)
				currentField = ""
			
			//Normal characters
			default: currentField.append(char)
			}
		}
		
		//Last line
		if !currentField.isEmpty { currentLine.append(currentField) }
		if !currentLine.isEmpty { result.append(currentLine) }
		
		//Finishing touchups
		
		//Remove all lines that are before the first line that should be respected
		instructionSet.firstLine.clamp(lower: 1, upper: result.count)
		result.removeFirst(instructionSet.firstLine-1)
		
		//Line length/cell count standartisation
		for line in result.enumerated() {
			let rowCount = instructionSet.rowCount + instructionSet.firstRow-1 //The rows are shortened later
			
			//Too short
			if line.element.count < rowCount {
				for _ in 1...(rowCount - line.element.count) {
					result[line.offset].append("")
				}
			}
			
			//Too long
			if line.element.count > rowCount {
				result[line.offset].removeLast(line.element.count - rowCount)
			}
		}
		
		//Remove all rows that are before the first row that should be respected
		instructionSet.firstRow.clamp(lower: 1, upper: .max)
		for line in result.enumerated() {
			result[line.offset].removeFirst(instructionSet.firstRow - 1)
		}
		
		return result
	}
	
	//Parsing directly from a file
	static func parse(url: URL, instructionSet: CSV.InstructionSet) throws -> [[String]] {
		//Politely ask for access to the file
		guard url.startAccessingSecurityScopedResource() else {throw CocoaError(.fileReadNoPermission)}
		
		//Decode
		let string = try String(contentsOf: url, encoding: instructionSet.encoding)
		let result = parse(string, instructionSet: instructionSet)
		
		//Finished with the access
		url.stopAccessingSecurityScopedResource()
		
		return result
	}
	
	
	
	//Parsing to CSVCodable object array
	static func parseToItems<Item: CSVDecodable>(_ stringTable: [[String]], configuration: [Int:Item.RowConfigurator]) -> [Item] {
		var returnArr: [Item] = []
		var indexCounter = 1
		
		for line in stringTable {
			if let newItem = Item(fromStringArray: line, configuration: configuration, index: indexCounter) {
				returnArr.append(newItem)
				indexCounter += 1
			}
		}
		
		return returnArr
	}
	
	static func parseToItems<Item: CSVDecodable>(url: URL, instructionSet: CSV.InstructionSet, configuration: [Int:Item.RowConfigurator]) throws -> [Item] {
		let stringTable = try CSV.parse(url: url, instructionSet: instructionSet)
		return parseToItems(stringTable, configuration: configuration)
	}
	
	
	
	//MARK: ENCODING TO STRING
	
	//directly from string array
	static func encode(_ table: [[String]]) -> String {
		
		var result: String = ""
		
		result.append("\u{FEFF}") //add UTF8 BOM
		
		for line in table {
			for field in line {
				//New field
				result.append("\"" + field + "\"" + ";")
			}
			//New line
			result.append("\r\n")
		}
		
		return result
	}
	
	
	
	//Making a table from items
	static func makeTableFromItems<Item: CSVEncodable>(_ items: [Item], configuration: [Int:Item.RowConfigurator], header: [[String]] = [[]]) -> [[String]] {
		var pureStringTable = header
		
		for item in items {
			pureStringTable.append(item.makeStringArray(configuration: configuration))
		}
		
		return pureStringTable
	}
	
	
	
	//From an array of CSVCodable items
	static func encode<Item: CSVEncodable>(_ items: [Item], configuration: [Int:Item.RowConfigurator]) -> String {
		return encode(makeTableFromItems(items, configuration: configuration))
	}
	
	
	
	//MARK: FILE TYPE
	
	//Actual file for SwiftUI
	struct FileDoc: FileDocument {
		static var readableContentTypes: [UTType] = [.commaSeparatedText]
		
		var string: String
		
		init(_ string: String) { self.string = string }
		
		init(_ table: [[String]]) { self.string = encode(table) }
		
		init<Item: CSVEncodable>(items: [Item], configuration: [Int:Item.RowConfigurator]) {
			self.string = encode(items, configuration: configuration)
		}
		
		init(configuration: ReadConfiguration) throws {
			guard let data = configuration.file.regularFileContents, let string = String(data: data, encoding: .utf8) else {
				throw CocoaError(.fileReadCorruptFile)
			}; self.string = string
		}
		
		func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
			let data = string.data(using: .utf8)!; return FileWrapper(regularFileWithContents: data)
		}
	}
	
	
	
	//MARK: MAPPING FUNCTIONS
	
	//Make it easier to map content with a RowConfigurator
	static func mapContent<RowConfigurator>(configuration: [Int:RowConfigurator], disregardCase: RowConfigurator?, contentMap: [RowConfigurator:String]) -> [String] {
		var returnArr: [String] = []
		
		for row in configuration.sorted(by: {$0.key < $1.key}) {
			guard disregardCase == nil || row.value != disregardCase else {continue}
			guard let content = contentMap[row.value] else {continue}
			returnArr.append(content)
		}
		
		return returnArr
	}
	
	//Mapping with functions for special cases
	static func mapContent<RowConfigurator>(configuration: [Int:RowConfigurator], disregardCase: RowConfigurator?, contentMap: [RowConfigurator:() -> String]) -> [String] {
		var returnArr: [String] = []
		
		for row in configuration.sorted(by: {$0.key < $1.key}) {
			guard disregardCase == nil || row.value != disregardCase else {continue}
			guard let content = contentMap[row.value] else {continue}
			returnArr.append(content())
		}
		
		return returnArr
	}
}
