//
//	AllocationView.swift
//  BSA2
//
//  Created by Dominik Stücheli on 22.03.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import SwiftUI



struct AllocationView: View {
	
	@Bindable var allocation: Allocation
	
	private func fixedRowWidths(allocation: Allocation) -> [Int:CGFloat] {
		var returnValue: [Int:CGFloat] = [1:2*standartPadding]
		var rowIndex: Int = 3
		if allocation.useGenderField { returnValue[rowIndex] = smallCellFixedSize; rowIndex += 1 }
		if allocation.useGroupField { returnValue[rowIndex] = smallCellFixedSize; rowIndex += 1 }
		if allocation.useProfileField { returnValue[rowIndex] = smallCellFixedSize; rowIndex += 1 }
		return returnValue
	}
	
	var body: some View {
		VStack(spacing: 0) {
			
			HStack(spacing: 0) {
				TitleTextCell(text: "Name")
				
				if allocation.useGenderField {
					TitleTextCell(text: "Geschlecht")
						.frame(maxWidth: smallCellFixedSize)
				}
				
				if allocation.useGroupField {
					TitleTextCell(text: "Klasse")
						.frame(maxWidth: smallCellFixedSize)
				}
				
				if allocation.useProfileField {
					TitleTextCell(text: "Profil")
						.frame(maxWidth: smallCellFixedSize)
				}
				
				ForEach(1...allocation.choiceAmount, id: \.self) { i in
					TitleTextCell(text: "\(i). Wahl")
				}
				
				if allocation.allowForMandatoryPartners {
					TitleTextCell(text: "Partner*in")
				}
			}
			.padding(.leading, 2*standartPadding + 1.5)
			.fixedSize(horizontal: false, vertical: true)
			
			.tableLines(lines: 1, rows: allocation.studentTableRowCount, fixedRowWidths: fixedRowWidths(allocation: allocation))
			
			VDivider()
			
			ScrollView { VStack(spacing: standartPadding*4) {
				ForEach(allocation.categories.indexSorted(), id: \.id) { category in
					AllocatedCategoryView(category: category)
				}
				
				UnAllocatedStudentTableView()
			} } .environment(allocation)
		}
	}
}
