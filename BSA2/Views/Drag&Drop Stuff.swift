//
//	Drag&Drop Stuff.swift
//  BSA2
//
//  Created by Dominik Stücheli on 29.05.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//



import Foundation
import SwiftUI
import SwiftData



struct LiveDropDestination: ViewModifier {
	
	var reference: (any PersistentModel)?
	var newOriginInformation: Any?
	var doOnHover: () -> Void
	
	@State private var isTargeted: Bool = false
	
	func body(content: Content) -> some View {
		content
			.dropDestination(for: ReferenceTransferable.self) { items, destination in
				ReferenceTransferable.reset()
				return true
			} isTargeted: { isHovering in
				isTargeted = isHovering
				if isHovering {
					doOnHover()
					if newOriginInformation != nil { ReferenceTransferable.originInformation = newOriginInformation }
				}
			}
		
			.background {
				if isTargeted && ReferenceTransferable.reference?.persistentModelID == reference?.persistentModelID {
					Color.gray.opacity(0.4)
				}
			}
	}
}

extension View {
	func liveDropDestination(for item: (any PersistentModel)?, newOriginInformation: Any? = nil, _ doOnHover: @escaping () -> Void) -> some View {
		modifier(LiveDropDestination(reference: item, newOriginInformation: newOriginInformation, doOnHover: doOnHover))
	}
}
