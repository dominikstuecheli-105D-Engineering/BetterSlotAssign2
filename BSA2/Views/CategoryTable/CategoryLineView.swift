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
	
    var body: some View {
		HStack(spacing: 0) {
			LineDragAndDropHandle()
			
			ConditionalTextCell($category.name, cellIndex: CellIndex(item: category, row: 1))
			
			ConditionalIntegerCell($category.number, cellIndex: CellIndex(item: category, row: 2))
			
			ConditionalIntegerCell($category.capacity, cellIndex: CellIndex(item: category, row: 3))
			
			ConditionalIntegerCell($category.minParticipantRequirement, cellIndex: CellIndex(item: category, row: 4))
		}
		.fixedSize(horizontal: false, vertical: true)
		
		//Drag&Drop
		.draggable(ReferenceTransferable(for: category)) {Color.clear}
		.liveDropDestination(for: category) {
			session.categories.moveFromTransferable(to: category.index)
		}
    }
}
