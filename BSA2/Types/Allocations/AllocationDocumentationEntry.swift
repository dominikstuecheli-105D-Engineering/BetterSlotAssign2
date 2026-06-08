//
//	AllocationDocumentationEntry.swift
//  BSA2
//
//  Created by Dominik Stücheli on 18.03.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import Foundation
import SwiftData
import SwiftUI



enum AllocationDocumentationEntryType: Int, Codable {
	case stageSeperator
	case action
	case manualAction
	case destructiveAction
	case error
	case exitError
	case dummy
	
	func color() -> Color {
		switch self {
		case .stageSeperator: return .green
		case .action: return .gray
		case .manualAction: return .gray
		case .destructiveAction: return .yellow
		case .error: return .orange
		case .exitError: return .red
		case .dummy: return .gray
		}
	}
	
	func title() -> String {
		switch self {
		case .stageSeperator: return ""
		case .action: return "Aktion"
		case .manualAction: return "Manuelle Aktion"
		case .destructiveAction: return "Destruktive Aktion"
		case .error: return "Error"
		case .exitError: return "Fataler Error"
		case .dummy: return "Dummy"
		}
	}
}



@Model class AllocationDocumentationEntry: PersistentArrayCompatible {
	
	var type: AllocationDocumentationEntryType
	var desc: String
	
	var index: Int
	var id = UUID()
	
	var stepCode: String
	
	init(_ stepCode: String, index: Int, _ type: AllocationDocumentationEntryType, _ desc: String) {
		self.type = type
		self.desc = desc
		self.index = index
		self.stepCode = stepCode
	}
}
