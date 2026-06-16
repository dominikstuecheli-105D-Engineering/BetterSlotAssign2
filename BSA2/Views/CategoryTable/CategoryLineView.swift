//
//	CategoryLineView.swift
//  BSA2
//
//  Created by Dominik Stücheli on 15.03.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import SwiftUI



struct CategoryLineView: View {
	
	@Bindable var category: Category
	@Environment(Session.self) var session: Session
	
	@FocusState.Binding var focusState: CellIndex?
	
    var body: some View {
		HStack(spacing: 0) {
			LineDragAndDropHandle()
			
			HDivider()
			
			ConditionalTextCell($category.name, focusState: $focusState, cellIndex: CellIndex(item: category, row: 1))
			
			HDivider()
			
			ConditionalIntegerCell($category.number, focusState: $focusState, cellIndex: CellIndex(item: category, row: 2))
			
			HDivider()
			
			ConditionalIntegerCell($category.capacity, focusState: $focusState, cellIndex: CellIndex(item: category, row: 3))
			
			HDivider()
			
			ConditionalIntegerCell($category.minParticipantRequirement, focusState: $focusState, cellIndex: CellIndex(item: category, row: 4))
		}
		.fixedSize(horizontal: false, vertical: true)
		
		//Drag&Drop
		.draggable(ReferenceTransferable(for: category)) {Color.clear}
		.liveDropDestination(for: category) {
			session.categories.moveFromTransferable(to: category.index)
		}
    }
}
