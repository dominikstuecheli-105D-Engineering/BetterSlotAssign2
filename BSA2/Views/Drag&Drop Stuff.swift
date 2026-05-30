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



@Observable class DragAndDropState {
	static var shared = DragAndDropState()
	var isDragging: Bool = false
}



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
					DispatchQueue.main.async {DragAndDropState.shared.isDragging = true}
				} else {
					DragAndDropState.shared.isDragging = false
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



struct DragAndDropStateAwareness: ViewModifier {
	func body(content: Content) -> some View {
		content
			.dropDestination(for: ReferenceTransferable.self) { items, destination in
				ReferenceTransferable.reset()
				return false
			} isTargeted: { isHovering in
				if isHovering {
					DispatchQueue.main.async {DragAndDropState.shared.isDragging = true}
				} else {
					DragAndDropState.shared.isDragging = false
				}
			}
	}
}

extension View {
	func dragAndDropStateAware() -> some View {
		modifier(DragAndDropStateAwareness())
	}
}
