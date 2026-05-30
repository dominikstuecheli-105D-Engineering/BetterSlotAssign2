//
//	AllocatedStudentLineView.swift
//  BSA2
//
//  Created by Dominik Stücheli on 22.03.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import SwiftUI



struct AllocatedStudentLineView: View {
	
	@Bindable var student: AllocatedStudent
	var draggableOriginIndex: Int
	@Environment(Allocation.self) var allocation: Allocation
	
	var body: some View {
		HStack(spacing: 0) {
			LineDragAndDropHandle()
			
			HDivider()
			
			PlainTextCell(text: student.name)
			
			HDivider()
			
			ForEach(1...allocation.choiceAmount, id: \.self) { i in
				let unwrapped: Int? = student.choices[i] ?? nil
				PlainTextCell(text: "\(unwrapped, default: "")") //Don't ask
				
				HDivider()
			}
			
			if allocation.allowForMandatoryPartners {
				PlainTextCell(text: student.mandatoryPartnerName)
			}
		}
		.fixedSize(horizontal: false, vertical: true)
		
		//Drag&Drop
		.draggable(ReferenceTransferable(for: student, originInformation: draggableOriginIndex)) {Color.clear}
		.liveDropDestination(for: student) {
			allocation.moveStudentFromTransferable(to: draggableOriginIndex, at: student.index)
		}
	}
}
