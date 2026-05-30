//
//	CSVExporter View.swift
//  BSA2
//
//  Created by Dominik Stücheli on 16.04.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers



struct CSVExporter: View {
	
	var getCSVTable: () -> (table: [[String]], fileName: String)
	
	@State var exporterPanelOpen: Bool = false
	@State var fileDocument: CSV.FileDoc? = nil
	@State var fileName: String? = nil
	
    var body: some View {
		RoundedCornerButton("Als CSV Exportieren", imageName: "square.and.arrow.up", color: .blue) {
			DispatchQueue.main.async {
				let CSVReturn = getCSVTable()
				fileDocument = CSV.FileDoc(CSVReturn.table)
				fileName = "\(CSVReturn.fileName).csv"
				exporterPanelOpen = true
			}
		}
		
		.fileExporter(isPresented: $exporterPanelOpen, document: fileDocument, contentType: .commaSeparatedText, defaultFilename: fileName) { result in
			switch result {
			case .success(let success):
				print("Successfully exported: \(success)")
			case .failure(let failure):
				print("Failed to export: \(failure)")
			}
		}
    }
}
