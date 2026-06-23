//
//	StudentTableView.swift
//  BSA2
//
//  Created by Dominik Stücheli on 12.03.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import SwiftUI



let smallCellFixedSize: CGFloat = 75



struct StudentTableView: View {
	
	@Environment(Session.self) var session: Session
	@Binding var scrollPosition: ScrollPosition
	
	@Environment(\.modelContext) var modelContext
	
	private func fixedRowWidths(session: Session) -> [Int:CGFloat] {
		var returnValue: [Int:CGFloat] = [1:2*standartPadding]
		var rowIndex: Int = 3
		if session.useGenderField { returnValue[rowIndex] = smallCellFixedSize; rowIndex += 1 }
		if session.useGroupField { returnValue[rowIndex] = smallCellFixedSize; rowIndex += 1 }
		if session.useProfileField { returnValue[rowIndex] = smallCellFixedSize; rowIndex += 1 }
		return returnValue
	}
	
	var body: some View {
		
		VStack(spacing: 0) {
			
			HStack(spacing: 0) {
				TitleTextCell(text: "Name")
				//HDivider()
				
				if session.useGenderField {
					TitleTextCell(text: "Geschlecht")
						.frame(maxWidth: smallCellFixedSize)
				}
				
				if session.useGroupField {
					TitleTextCell(text: "Klasse")
						.frame(maxWidth: smallCellFixedSize)
				}
				
				if session.useProfileField {
					TitleTextCell(text: "Profil")
						.frame(maxWidth: smallCellFixedSize)
				}
				
				ForEach(1...session.choiceAmount, id: \.self) { i in
					TitleTextCell(text: "\(i). Wahl")
				}
				
				if session.allowForMandatoryPartners {
					TitleTextCell(text: "Partner*in")
				}
			}
			.padding(.leading, 2*standartPadding + 1.5)
			.fixedSize(horizontal: false, vertical: true)
			.tableLines(lines: 1, rows: session.studentTableRowCount+1, fixedRowWidths: fixedRowWidths(session: session))
			
			VDivider()
			
			ScrollView { LazyVStack(spacing: 0) {
				ForEach(session.students.indexSorted(), id: \.id) { student in
					StudentLineView(student: student)
				}
			} .tableLines(lines: session.students.count, rows: session.studentTableRowCount+1, fixedRowWidths: fixedRowWidths(session: session)) } .scrollPosition($scrollPosition) .scrollIndicators(.hidden)
			
			//Keyboard shortcuts
				.onKeyPress { press in
					let currentlySelectedStudentIndex = GlobalCellFocus.shared.state?.line ?? 1
					
					//Adding a student after the currently selected one
					if press.key == .downArrow && press.modifiers.contains(.shift) {
						let newStudent = Student(index: currentlySelectedStudentIndex+1)
						session.students.add(newStudent)
						session.provideCellConditionHostsForStudentTableToErrorCollector()
						
						//Setting the focusState to the name field of the newly added student. Delayed to give SwiftUI time to build the views... :(
						DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
							scrollPosition.scrollTo(id: newStudent.id)
							GlobalCellFocus.shared.cellObservedState = CellIndex(item: newStudent, row: 1)
						}
						return .handled
					}
					
					//Removing the currently selected student
					if press.key == .upArrow && press.modifiers.contains(.shift) && session.students.count > 1 {
						session.students.remove(itemPosition: currentlySelectedStudentIndex, from: modelContext)
						session.provideCellConditionHostsForStudentTableToErrorCollector()
						
						let previousStudentIndex = currentlySelectedStudentIndex-1
						
						DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
							scrollPosition.scrollTo(id: session.students.getIndex(previousStudentIndex)?.id ?? UUID())
							GlobalCellFocus.shared.cellObservedState = CellIndex(line: previousStudentIndex, row: 1)
						}
						return .handled
					}
					
					return .ignored
				}
			
			//Shortcut dictionary at the bottom
			if GlobalCellFocus.shared.state != nil {
				VDivider()
				
				Text("**[Tab]** = nächstes Feld, **[Shift+downArrow]** = neuer Schüler/neue Schülerin, **[Shift+upArrow]** = Schüler*in löschen") .padding(standartPadding) .foregroundStyle(.gray)
			}
			
		}
		
		.onAppear {
			session.provideCellConditionHostsForStudentTableToErrorCollector()
		}
		
		.onChange(of: session.students.count) { _,_ in
			session.provideCellConditionHostsForStudentTableToErrorCollector()
		}
		
		.onChange(of: session.choiceAmount) { _,_ in
			session.provideCellConditionHostsForStudentTableToErrorCollector()
		}
		
		.onChange(of: session.allowForMandatoryPartners) { _,_ in
			session.provideCellConditionHostsForStudentTableToErrorCollector()
		}
		
		.onChange(of: session.useGenderField) { _,_ in
			session.provideCellConditionHostsForStudentTableToErrorCollector()
		}
		
		.onChange(of: session.useGroupField) { _,_ in
			session.provideCellConditionHostsForStudentTableToErrorCollector()
		}
		
		.onChange(of: session.useGenderField) { _,_ in
			session.provideCellConditionHostsForStudentTableToErrorCollector()
		}
		
		.onChange(of: session.id) {
			session.provideCellConditionHostsForStudentTableToErrorCollector()
		}
	}
}
