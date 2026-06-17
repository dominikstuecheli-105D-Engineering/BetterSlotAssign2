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
			
			if session.useGenderField {
				ConditionalTextCell($student.gender, focusState: $focusState, cellIndex: CellIndex(item: student, row: 2))
					.frame(maxWidth: smallCellFixedSize)
				HDivider()
			}
			
			if session.useGroupField {
				ConditionalTextCell($student.group, focusState: $focusState, cellIndex: CellIndex(item: student, row: 3))
					.frame(maxWidth: smallCellFixedSize)
				HDivider()
			}
			
			if session.useProfileField {
				ConditionalTextCell($student.profile, focusState: $focusState, cellIndex: CellIndex(item: student, row: 4))
					.frame(maxWidth: smallCellFixedSize)
				HDivider()
			}
			
			ForEach(1...session.choiceAmount, id: \.self) { i in
				ConditionalIntegerCell(Binding(get: {return student.choices[i] ?? nil}, set: {v in student.choices[i] = v}), focusState: $focusState, cellIndex: CellIndex(item: student, row: session.studentTableFirstChoiceRowIndex()-1+i))
				HDivider()
			}
			
			if session.allowForMandatoryPartners {
				
				ConditionalTextCell($student.mandatoryPartner, focusState: $focusState, cellIndex: CellIndex(item: student, row: session.studentTableRowCount()))
			}
		}
		.fixedSize(horizontal: false, vertical: true)
		
		//Drag&Drop
		.draggable(ReferenceTransferable(for: student)) {Color.clear}
		.liveDropDestination(for: student) {
			session.students.moveFromTransferable(to: student.index)
		}
    }
}
