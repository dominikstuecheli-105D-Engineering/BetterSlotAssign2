//
//	AllocationList.swift
//  BSA2
//
//  Created by Dominik Stücheli on 04.04.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import SwiftUI

struct AllocationList: View {
	
	@Environment(Session.self) var session: Session
	@Binding var selectedAllocation: Allocation?
	
	@Binding var searchString: String
	
	@State var displayedAllocations: [Allocation] = []
	
	var body: some View {
		ScrollView { LazyVStack(spacing: standartPadding) {
			ForEach(displayedAllocations.indexReverseSorted()) { allocation in
				AllocationItemListView(allocation, selectedAllocation: $selectedAllocation)
					.onTapGesture {selectedAllocation = allocation}
			}
			
			Spacer()
		} .padding(standartPadding) }
		
		.onChange(of: searchString) {
			displayedAllocations = session.allocations.searchBy(searchString)
		}
		
		.onAppear {
			displayedAllocations = session.allocations.searchBy(searchString)
		}
	}
}
