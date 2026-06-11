//
//	PersistentSettings.swift
//  BSA2
//
//  Created by Dominik Stücheli on 04.06.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import Foundation
import SwiftData



@Model class PersistentSettings {
	
	var lastOpenedSession: Session? = nil
	var leftSidebarOpen: Bool = true
	var rightSidebarOpen: Bool = true
	
	init() {}
	
	static func fetch(from modelContext: ModelContext) -> PersistentSettings? {
		guard let allObjects: [PersistentSettings] = try? modelContext.fetch(FetchDescriptor<PersistentSettings>()) else {
			print("Error while fetching PersistentSettings object"); return nil
		}
		
		if let first = allObjects.first {
			//If an object exists
			
			if allObjects.count > 1 {
				///If for some reason there are multiple objects, delete all that are unwanted
				for object in allObjects { if object != first { modelContext.delete(object) } }
			}
			
			return first
		} else {
			//If no object exists yet
			let new = PersistentSettings()
			modelContext.insert(new)
			return new
		}
	}
}
