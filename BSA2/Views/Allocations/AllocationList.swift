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
	
	var body: some View {
		ScrollView { LazyVStack(spacing: standartPadding) {
			ForEach(session.allocations.indexSorted().reversed()) { allocation in
				AllocationItemListView(allocation, selectedAllocation: $selectedAllocation)
					.onTapGesture {selectedAllocation = allocation}
			}
			
			Spacer()
		} .padding(standartPadding) }
	}
}
