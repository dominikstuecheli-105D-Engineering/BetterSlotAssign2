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
	case dummy ///I changed the amount of cases but didnt want to break existing data so this exists now
	
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
	var timestamp: TimeInterval = 0
	
	init(_ stepCode: String, timestamp: TimeInterval, index: Int, _ type: AllocationDocumentationEntryType, _ desc: String) {
		self.type = type
		self.desc = desc
		self.index = index
		self.stepCode = stepCode
		self.timestamp = timestamp
	}
}



struct AllocationDocumentationEntryView: View {
	
	var entry: AllocationDocumentationEntry
	
	var body: some View {
		if entry.type == .stageSeperator {
			HStack(spacing: standartPadding) {
				Text(">\(entry.desc)<") .font(.footnote) .foregroundStyle(.gray.opacity(0.6)) .fontWeight(.bold)
					.lineLimit(.max)
			}
		} else {
			HStack(spacing: standartPadding) {
				RoundedRectangle(cornerRadius: standartPadding/2)
					.frame(width: standartPadding)
					.foregroundStyle(entry.type.color())
				
				VStack {
					Text("\(entry.stepCode), \(entry.type.title()), bei \(String(format:"%.3f",entry.timestamp))s") .font(.footnote) .foregroundStyle(.gray.opacity(0.6)) .fontWeight(.bold)
						.frame(maxWidth: .infinity, alignment: .leading)
					Text(entry.desc)
						.frame(maxWidth: .infinity, alignment: .leading)
				}
			}
		}
	}
}



extension [AllocationDocumentationEntry] {
	func documentStudentMove(student: AllocatedStudent, partner: AllocatedStudent?) {
		
	}
}



enum AllocationDocumentationEntryTypeNEW: Int, Codable {
	case stageSeperator
	case manualAction
	case destructiveAction
	case error
	case exitError
	
	func color() -> Color {
		switch self {
		case .stageSeperator: return .green
		case .manualAction: return .gray
		case .destructiveAction: return .yellow
		case .error: return .orange
		case .exitError: return .red
		}
	}
	
	func title() -> String {
		switch self {
		case .stageSeperator: return ""
		case .manualAction: return "Manuelle Aktion"
		case .destructiveAction: return "Destruktive Aktion"
		case .error: return "Error"
		case .exitError: return "Fataler Error"
		}
	}
}
