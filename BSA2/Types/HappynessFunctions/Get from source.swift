//
//	Get from source.swift
//  BSA2
//
//  Created by Dominik Stücheli on 31.07.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import Foundation
import SwiftData



//This file contains all code related to getting LUA files from the github servers to ensure that the built-in happyness functions are always up-to-date.

//By "built-in" I mean they are shipped with the app and are not editable by the user. However, built-in happyness functions are not really bound to any app build, so new ones or changes are theoratically also not bound to a new release.

//First, the "list" file is fetched and parsed. That file contains a list of all built-in happyness functions' URLs as well as some metadata like the displayed title and the description. The "list" file is a CSV formatted as follows:
///`"URL";"displayed title";"description"

//Since now the URLs of all currently built-in happyness functions are known, that list is compared with the locally stored one and differences are corrected locally.



fileprivate let builtInHappynessFunctionsURL = "https://raw.githubusercontent.com/dominikstuecheli-105D-Engineering/BetterSlotAssign2/main/BSA2/Types/HappynessFunctions/Built-in/list.csv"
fileprivate let builtInHappyinessFunctionListCSVRowConfiguration: [Int:HappynessFunctionDownloadData.RowConfigurator] = [0:.url, 1:.niceTitle, 2:.desc]
fileprivate let builtInHappyinessFunctionListCSVParserInstructionSet: CSV.InstructionSet = {
	let instructionSet: CSV.InstructionSet = .init(firstLine: 2, firstRow: 1, rowCount: 3)
	instructionSet.seperator = ","
	return instructionSet
}()


///Downloads a file from a server
func downloadFile(from urlString: String) async throws -> Data {
	guard let url = URL(string: urlString) else { throw URLError(.badURL) }
	let (data, _) = try await URLSession.shared.data(from: url)
	return data
}



///Converts Data to String assuming the Data is readable as a String, otherwise, you know, error handling
func dataToString(_ data: Data) throws -> String {
	guard let string = String(data: data, encoding: .utf8) else {
		throw NSError(domain: "Decoding", code: 0, userInfo: [NSLocalizedDescriptionKey: "Data could not be converted to String"])
	}
	
	return string
}



struct HappynessFunctionDownloadData: CSVDecodable {
	
	let url: String
	let niceTitle: String
	let desc: String
	
	init?(fromStringArray stringArray: [String], configuration: [Int:RowConfigurator], index: Int) {
		if let urlIndex = configuration.first(where: {$1 == .url}) {
			guard stringArray.count > urlIndex.key else { return nil }
			self.url = stringArray[urlIndex.key]
		} else { return nil }
		
		if let niceTitleIndex = configuration.first(where: {$1 == .niceTitle}) {
			guard stringArray.count > niceTitleIndex.key else { return nil }
			self.niceTitle = stringArray[niceTitleIndex.key]
		} else { return nil }
		
		if let descIndex = configuration.first(where: {$1 == .desc}) {
			guard stringArray.count > descIndex.key else { return nil }
			self.desc = stringArray[descIndex.key]
		} else { return nil }
	}
	
	enum RowConfigurator {
		case url
		case niceTitle
		case desc
	}
}



func updateBuiltInHappynessFunctions(in modelContext: ModelContext) { Task {
	do {
		let listData = try await downloadFile(from: builtInHappynessFunctionsURL) //Download as Data
		let listString = try dataToString(listData) //Convert Data to String
		guard listString != "404: Not Found" else { throw URLError(.fileDoesNotExist) }
		
		let listCSV: [[String]] = CSV.parse(listString, instructionSet: builtInHappyinessFunctionListCSVParserInstructionSet) //Convert the String, which is really a CSV, to such a CSV/String table
		let list: [HappynessFunctionDownloadData] = CSV.parseToItems(listCSV, configuration: builtInHappyinessFunctionListCSVRowConfiguration) //Convert to nice-to-use objects
		
		var happynessFunctions = try modelContext.fetch(FetchDescriptor<HappynessFunction>())
		var happynessFunctionsFoundInSource: Set<HappynessFunction> = []
		
		for downloadData in list {
			let downloadedData = try await downloadFile(from: downloadData.url)
			let downloadedLUAString = try dataToString(downloadedData)
			
			if let existingHappynessFunction = happynessFunctions.first(where: {$0.sourceLink == downloadData.url}) {
				existingHappynessFunction.name = downloadData.niceTitle
				existingHappynessFunction.desc = downloadData.desc
				existingHappynessFunction.code = downloadedLUAString
				existingHappynessFunction.timestamp = .now //The timestamp represents the last time it has been updated
				happynessFunctionsFoundInSource.insert(existingHappynessFunction)
				existingHappynessFunction.updateFromSourceStatus = "Last overridden from source on \(Date.now.formatted())"
			} else {
				let newHappynessFunction = HappynessFunction(from: downloadData, code: downloadedLUAString)
				modelContext.insert(newHappynessFunction)
				happynessFunctions.append(newHappynessFunction)
				happynessFunctionsFoundInSource.insert(newHappynessFunction)
				newHappynessFunction.updateFromSourceStatus = "Created on \(Date.now.formatted())"
			}
		}
		
		for happynessFunction in happynessFunctions {
			guard happynessFunction.sourceLink != nil else {continue}
			
			if !happynessFunctionsFoundInSource.contains(happynessFunction) {
				happynessFunctions.removeAll(where: {$0 == happynessFunction})
				modelContext.delete(happynessFunction)
				happynessFunction.updateFromSourceStatus = "Marked for deletion"
			}
		}
	} catch {
		print(error.localizedDescription)
	}
} }



///Replaces the https://raw.githubusercontent.com/... with the more human-accessible https://github.com/... one
func properGithubLinkFromRawUserContentLink(_ rawUserContentLink: String) -> String {
	var copy = rawUserContentLink
	copy.replace("https://raw.githubusercontent.com", with: "https://github.com")
	copy.replace("/main/", with: "/blob/main/") //I dont know what blob means but the github URLs have it
	return copy
}
