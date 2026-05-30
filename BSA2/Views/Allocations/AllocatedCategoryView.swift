//
//	AllocatedCategoryView.swift
//  BSA2
//
//  Created by Dominik Stücheli on 22.03.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import SwiftUI



struct AllocatedCategoryView: View {
	
	@Bindable var category: AllocatedCategory
	@Environment(Allocation.self) var allocation: Allocation
	
	var body: some View {
		VStack(spacing: 0) {
			
			HStack(spacing: standartPadding) {
				Text("\(category.index): \(category.name)") .bold()
				Text("\(category.students.count) Schüler*innen (Max: \(category.capacity), Min: \(category.minParticipants))") .opacity(0.7)
			} .padding(standartPadding)
		
			VDivider()
			
			ForEach(category.students.indexSorted(), id: \.id) { student in
				AllocatedStudentLineView(student: student, draggableOriginIndex: category.index)
				
				VDivider()
			}
			
			//Placeholder to also be able to move students here if empty
			if category.students.count == 0 {
				PlainTextCell(text: "")
					.liveDropDestination(for: nil) {
						allocation.moveStudentFromTransferable(to: category.index, at: 1)
					}
			}
			
		}
	}
}
