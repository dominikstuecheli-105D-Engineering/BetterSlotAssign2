//
//	StudentLineView.swift
//  BSA2
//
//  Created by Dominik Stücheli on 12.03.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import SwiftUI



struct StudentLineView: View {
	
	@Bindable var student: Student
	@Environment(Session.self) var session: Session
	
	@FocusState.Binding var focusState: CellIndex?
	
    var body: some View {
		HStack(spacing: 0) {
			LineDragAndDropHandle()
			
			HDivider()
			
			ConditionalTextCell($student.name, focusState: $focusState, cellIndex: CellIndex(item: student, row: 1))
			HDivider()
			
			ForEach(1...session.choiceAmount, id: \.self) { i in
				ConditionalIntegerCell(Binding(get: {return student.choices[i] ?? nil}, set: {v in student.choices[i] = v}), focusState: $focusState, cellIndex: CellIndex(item: student, row: i+1))
				
				HDivider()
			}
			
			if session.allowForMandatoryPartners {
				
				ConditionalTextCell($student.mandatoryPartner, focusState: $focusState, cellIndex: CellIndex(item: student, row: session.choiceAmount+2))
			}
		}
		.fixedSize(horizontal: false, vertical: true)
		.id(student.index)
		
		//Drag&Drop
		.draggable(ReferenceTransferable(for: student)) {Color.clear}
		.liveDropDestination(for: student) {
			session.students.moveFromTransferable(to: student.index)
		}
    }
}
