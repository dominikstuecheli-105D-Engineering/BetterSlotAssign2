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
	
	@FocusState.Binding var focusState: Int?
	
    var body: some View {
		HStack(spacing: 0) {
			LineDragAndDropHandle()
			
			HDivider()
			
			ConditionalTextCell($category.name, focusState: $focusState, focusIndex: focusIndex(item: category, row: 1, rowCount: 4))
			
			HDivider()
			
			ConditionalIntegerCell($category.number, focusState: $focusState, focusIndex: focusIndex(item: category, row: 2, rowCount: 4))
			
			HDivider()
			
			ConditionalIntegerCell($category.capacity, focusState: $focusState, focusIndex: focusIndex(item: category, row: 3, rowCount: 4))
			
			HDivider()
			
			ConditionalIntegerCell($category.minParticipantRequirement, focusState: $focusState, focusIndex: focusIndex(item: category, row: 4, rowCount: 4))
		}
		.fixedSize(horizontal: false, vertical: true)
		
		//Drag&Drop
		.draggable(ReferenceTransferable(for: category)) {Color.clear}
		.liveDropDestination(for: category) {
			session.categories.moveFromTransferable(to: category.index)
		}
    }
}

#Preview {
	@Previewable @State var category = Category("", number: nil, index: 1)
	@Previewable @FocusState var focusState: Int?
	
	CategoryLineView(category: category, focusState: $focusState)
		.environment(Session())
		.padding(50)
}
