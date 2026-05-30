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
	
	var body: some View {
		VStack(spacing: 0) {
			
			HStack(spacing: 0) {
				TitleTextCell(text: "Name")
				HDivider()
				
				ForEach(1...allocation.choiceAmount, id: \.self) { i in
					TitleTextCell(text: "\(i). Wahl")
					HDivider()
				}
				
				if allocation.allowForMandatoryPartners {
					TitleTextCell(text: "Partner*in")
				}
			}
			.padding(.leading, 2*standartPadding + 1.5)
			.fixedSize(horizontal: false, vertical: true)
			
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
