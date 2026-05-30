//
//	CSVImporter View.swift
//  BSA2
//
//  Created by Dominik Stücheli on 17.03.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers



struct RudimentaryTable: View {
	
	var table: [[String]]
	
	var body: some View {
		VStack(spacing: 0) { VDivider(); ForEach(table.indices, id: \.self) { lineIndex in
			HStack(spacing: 0) { HDivider(); ForEach(table[lineIndex].indices, id: \.self) { colIndex in
				HStack(spacing: 0) {
					Spacer(minLength: 3)
					Text(table[lineIndex][colIndex])
					Spacer(minLength: 3)
					HDivider()
				}
			} }; VDivider()
		} }
	}
}



struct CSVImporter: View {
	
	@State var fileImporterOpen: Bool = false
	@State var parserPanelOpen: Bool = false
	
	@Binding var selectedWindow: SelectedWindow
	
	@Environment(\.modelContext) var modelContext
	@Environment(Session.self) var session: Session
	
	@State var instructionSet = CSV.InstructionSet()
	
	@State var studentImportRows: [Int:Student.RowConfigurator] = [:]
	@State var categoryImportRows: [Int:Category.RowConfigurator] = [:]
	
	@State var url: URL?
	@State var decodedTable: [[String]] = []
	
	@State var importTo: SelectedWindow = .studentTable
	@State var overrideExistingTable: Bool = false
	
	func parse() {
		studentImportRows = Student.RowConfigurator.standartConfiguration(rowCount: instructionSet.rowCount)
		categoryImportRows = Category.RowConfigurator.standartConfiguration(rowCount: instructionSet.rowCount)
		
		if let url {
			DispatchQueue.main.async {
				if let newTable = try? CSV.parse(url: url, instructionSet: instructionSet) {
					decodedTable = newTable
				} else {
					decodedTable = []
				}
			}
		}
	}
	
    var body: some View {
		RoundedCornerButton("CSV Importieren", imageName: "folder", color: .blue) {
			fileImporterOpen = true
		}
		
		//File importer
		.fileImporter(isPresented: $fileImporterOpen, allowedContentTypes: [.commaSeparatedText], allowsMultipleSelection: false) { result in
			switch result {
			case .success(let urls):
				guard let firstUrl = urls.first else {return}
				url = firstUrl
				fileImporterOpen = false
				parserPanelOpen = true
				
				parse()
				
			case .failure(let error):
				print(error.localizedDescription)
			}
		}
		
		//Parser panel
		.sheet(isPresented: $parserPanelOpen) {
			VStack {
				
				//Parser settings
				HStack {
					Picker("Kodierung:", selection: $instructionSet.encoding) {
						Text("UTF-8") .tag(String.Encoding.utf8)
						Text("Windows-CP1252") .tag(String.Encoding.windowsCP1252)
						Text("isoLatin-1") .tag(String.Encoding.isoLatin1)
					} .onChange(of: instructionSet.encoding) { _,_ in
						parse()
					}
					
					Picker("Trennzeichen:", selection: $instructionSet.seperator) {
						Text("Semikolon ;") .tag(Character(";"))
						Text("Komma ,") .tag(Character(","))
					} .onChange(of: instructionSet.seperator) { _,_ in
						parse()
					}
				}
				
				HStack {
					Text("Beginnen bei Zeile:")
					TextField("Zeile", value: $instructionSet.firstLine, format: .number) .frame(width: 40)
						.onChange(of: instructionSet.firstLine) { _,_ in
							if instructionSet.firstLine <= 1 {instructionSet.firstLine = 1}
							parse()
						}
					
					Text("Berücksichtigte Spalten:")
					TextField("Spalten", value: $instructionSet.rowCount, format: .number) .frame(width: 40)
						.onChange(of: instructionSet.rowCount) { _,_ in
							if instructionSet.rowCount <= 1 {instructionSet.rowCount = 1}
							parse()
						}
					
					Picker("", selection: $overrideExistingTable) {
						Text("Bestehende Liste ergänzen") .tag(false)
						Text("Bestehende Liste überschreiben") .tag(true)
					}
				}
				
				//Specific import settings
				HStack {
					Picker("Importieren nach:", selection: $importTo) {
						Text("Schülerliste") .tag(SelectedWindow.studentTable)
						Text("Kategorienliste") .tag(SelectedWindow.categoryTable)
					}
					
					Button("Importieren") {
						parserPanelOpen = false
						
						DispatchQueue.main.async {
							if importTo == .studentTable {
								session.importStudents(fromStringArray: decodedTable, configuration: studentImportRows, overrideExisting: overrideExistingTable, from: modelContext)
								selectedWindow = .studentTable
							} else if importTo == .categoryTable {
								session.importCategories(fromStringArray: decodedTable, configuration: categoryImportRows, overrideExisting: overrideExistingTable, from: modelContext)
								selectedWindow = .categoryTable
							}
						}
					} .buttonStyle(.borderedProminent)
					
					//Set the import destination to the currently opened window
						.onAppear {importTo = selectedWindow}
				}
				
				Divider()
				
				Text("Überprüfen sie hier, ob alles richtig dekodiert wurde und passen sie allenfalls die Einstellungen an. Die Liste wird beim Importieren wie hier angezeigt übernommen; Titelzeilen sollten also übersprungen werden. Teilen sie die Spalten den richtigen Angaben zu; mit \"--\" markierte Spalten werden übersprungen.") .opacity(0.7)
				
				Divider()
				
				//Row selectors
				HStack { ForEach(0...instructionSet.rowCount-1, id: \.self) { i in
					VStack {
						Text("Spalte \(i)")
						
						if importTo == .studentTable {
							Picker(selection: $studentImportRows[i]) {
								Text("--") .tag(Student.RowConfigurator.disregarded)
								Text("Name") .tag(Student.RowConfigurator.name)
								Text("Kategoriewahl (von Links nach Rechts)") .tag(Student.RowConfigurator.choice)
								Text("zwingende Partner") .tag(Student.RowConfigurator.mandatoryPartner)
							} label: {}
						} else if importTo == .categoryTable {
							Picker(selection: $categoryImportRows[i]) {
								Text("--") .tag(Category.RowConfigurator.disregarded)
								Text("Name") .tag(Category.RowConfigurator.name)
								Text("Nummer") .tag(Category.RowConfigurator.number)
								Text("Kapazität") .tag(Category.RowConfigurator.capacity)
								Text("mind. Teilnehmer") .tag(Category.RowConfigurator.minMemberCount)
							} label: {}
						}
					}
				} }
				
				//Decoded table
				ScrollView {
					RudimentaryTable(table: decodedTable)
				}
				
			} .padding()
		}
    }
}
