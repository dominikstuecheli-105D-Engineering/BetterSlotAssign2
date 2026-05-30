//
//	StudentTableView.swift
//  BSA2
//
//  Created by Dominik Stücheli on 12.03.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import SwiftUI



struct StudentTableView: View {
	
	@Environment(Session.self) var session: Session
	@FocusState.Binding var focusState: Int?
	@Binding var scrollPosition: ScrollPosition
	
	@Environment(\.modelContext) var modelContext
	
	var body: some View {
		
		VStack(spacing: 0) {
			
			HStack(spacing: 0) {
				TitleTextCell(text: "Name")
				HDivider()
				
				ForEach(1...session.choiceAmount, id: \.self) { i in
					TitleTextCell(text: "\(i). Wahl")
					HDivider()
				}
				
				if session.allowForMandatoryPartners {
					TitleTextCell(text: "Partner*in")
				}
			}
			.padding(.leading, 2*standartPadding + 1.5)
			.fixedSize(horizontal: false, vertical: true)
			
			VDivider()
			
			ScrollView { LazyVStack(spacing: 0) {
				ForEach(session.students.indexSorted(), id: \.id) { student in
					StudentLineView(student: student, focusState: $focusState)
					
					VDivider()
				}
			} } .scrollPosition($scrollPosition)
			
			//Keyboard shortcuts
				.onKeyPress { press in
					let currentlySelectedStudentIndex = lineIndexFromFocusIndex(focusIndex: focusState ?? 0, rowCount: session.studentTableRowCount())
					
					//Adding a student after the currently selected one
					if press.key == .downArrow && press.modifiers.contains(.shift) {
						let newStudent = Student(index: currentlySelectedStudentIndex+1)
						session.students.add(newStudent)
						
						//Setting the focusState to the name field of the newly added student. Delayed to give SwiftUI time to build the views... :(
						DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
							scrollPosition.scrollTo(id: newStudent.index)
							focusState = focusIndex(item: newStudent, row: 1, rowCount: session.studentTableRowCount())
						}
						return .handled
					}
					
					//Removing the currently selected student
					if press.key == .upArrow && press.modifiers.contains(.shift) && session.students.count >= 1 {
						session.students.remove(itemPosition: currentlySelectedStudentIndex, from: modelContext)
						
						let previousStudentIndex = currentlySelectedStudentIndex-1
						
						DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
							scrollPosition.scrollTo(id: previousStudentIndex)
							focusState = focusIndex(line: previousStudentIndex, row: 1, rowCount: session.studentTableRowCount())
						}
						return .handled
					}
					
					return .ignored
				}
			
			//Shortcut dictionary at the bottom
			if focusState != nil {
				VDivider()
				
				Text("**[Tab]** = nächstes Feld, **[Shift+downArrow]** = neuer Schüler/neue Schülerin, **[Shift+upArrow]** = Schüler*in löschen") .padding(standartPadding) .foregroundStyle(.gray)
			}
			
		}
	}
}

#Preview {
	@Previewable @State var session = Session()
	
	@Previewable @FocusState var focusState: Int?
	@Previewable @State var scrollPosition = ScrollPosition()
	
	StudentTableView(focusState: $focusState, scrollPosition: $scrollPosition)
		.environment(session)
		.padding(30)
}
