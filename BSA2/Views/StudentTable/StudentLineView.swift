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
	
    var body: some View {
		HStack(spacing: 0) {
			LineDragAndDropHandle()
			
			ConditionalTextCell($student.name, cellIndex: CellIndex(item: student, row: 1))
				.markWhenSearchTokenMatched(student, matchingToken: .name)
			
			if session.useGenderField {
				ConditionalTextCell($student.gender, cellIndex: CellIndex(item: student, row: 2))
					.frame(maxWidth: smallCellFixedSize)
					.markWhenSearchTokenMatched(student, matchingToken: .gender)
			}
			
			if session.useGroupField {
				ConditionalTextCell($student.group, cellIndex: CellIndex(item: student, row: 3))
					.frame(maxWidth: smallCellFixedSize)
					.markWhenSearchTokenMatched(student, matchingToken: .group)
			}
			
			if session.useProfileField {
				ConditionalTextCell($student.profile, cellIndex: CellIndex(item: student, row: 4))
					.frame(maxWidth: smallCellFixedSize)
					.markWhenSearchTokenMatched(student, matchingToken: .profile)
			}
			
			ForEach(1...session.choiceAmount, id: \.self) { i in
				ConditionalIntegerCell(Binding(get: {return student.choices[i] ?? nil}, set: {v in student.choices[i] = v}), cellIndex: CellIndex(item: student, row: session.studentTableFirstChoiceRowIndex-1+i))
			}
			
			if session.allowForMandatoryPartners {
				ConditionalTextCellWithSuggestionAcceptIndicator($student.mandatoryPartner, cellIndex: CellIndex(item: student, row: session.studentTableRowCount))
					.markWhenSearchTokenMatched(student, matchingToken: .mandatoryPartner)
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
