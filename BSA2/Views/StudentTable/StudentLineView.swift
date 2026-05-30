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
	
	@FocusState.Binding var focusState: Int?
	
    var body: some View {
		HStack(spacing: 0) {
			LineDragAndDropHandle()
			
			HDivider()
			
			ConditionalTextCell($student.name, focusState: $focusState, focusIndex: focusIndex(item: student, row: 1, rowCount: session.studentTableRowCount())) { _ in
				return student.nameConditon(in: session)
			}
			
			HDivider()
			
			ForEach(1...session.choiceAmount, id: \.self) { i in
				ConditionalIntegerCell(Binding(get: {return student.choices[i] ?? nil}, set: {v in student.choices[i] = v}), focusState: $focusState, focusIndex: focusIndex(item: student, row: i+1, rowCount: session.studentTableRowCount())) { value in
					return student.choiceCondition(index: i, value: value, session: session)
				}
				
				HDivider()
			}
			
			if session.allowForMandatoryPartners {
				
				ConditionalTextCell($student.mandatoryPartner, focusState: $focusState, focusIndex: focusIndex(item: student, row: session.choiceAmount+2, rowCount: session.studentTableRowCount())) { _ in
					return student.mandatoryPartnerCondition(session: session)
					
				}
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

#Preview {
	@Previewable @FocusState var focusState: Int?
	
	StudentLineView(student: Student("Name", choices: [1:1, 2:2], index: 1), focusState: $focusState)
		.padding(50)
}
