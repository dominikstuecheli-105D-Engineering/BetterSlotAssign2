//
//	UnAllocatedStudentTableView.swift
//  BSA2
//
//  Created by Dominik Stücheli on 22.03.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import SwiftUI



struct UnAllocatedStudentTableView: View {
	
	@Environment(Allocation.self) var allocation: Allocation
	
	@Binding var searchString: String
	@State var displayedStudents: [AllocatedStudent] = []
	
	var body: some View {
		VStack(spacing: 0) {
			
			HStack(spacing: standartPadding) {
				Text("Nicht zugeteilte Schüler*innen") .bold()
				Text("\(allocation.unAllocatedStudents.count) Schüler") .opacity(0.7)
			} .padding(standartPadding)
		
			VDivider()
			
			ForEach(displayedStudents.indexSorted(), id: \.id) { student in
				AllocatedStudentLineView(student: student, draggableOriginIndex: 0)
				
				VDivider()
			}
			
			//Placeholder to also be able to move students here if empty
			if allocation.unAllocatedStudents.count == 0 {
				PlainTextCell(text: "")
					.liveDropDestination(for: nil) {
						allocation.moveStudentFromTransferable(to: 0, at: 1)
					}
			}
		}
		
		.onChange(of: searchString) {
			displayedStudents = allocation.unAllocatedStudents.searchBy(searchString)
		}
		
		.onAppear {
			displayedStudents = allocation.unAllocatedStudents.searchBy(searchString)
		}
	}
}
