//
//	AllocationListView.swift
//  BSA2
//
//  Created by Dominik Stücheli on 19.03.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import SwiftUI



struct AllocationItemListView: View {
	
	var allocation: Allocation
	@Binding var selectedAllocation: Allocation?
	
	@State var isHovering: Bool = false
	
	@Environment(\.modelContext) var modelContext
	@Environment(Session.self) var session: Session
	
	init(_ allocation: Allocation, selectedAllocation: Binding<Allocation?>) {
		self.allocation = allocation
		self._selectedAllocation = selectedAllocation
	}
	
	var body: some View {
		VStack(spacing: standartPadding/2) {
			HStack(spacing: standartPadding) {
				Text(allocation.name)
				
				Text(allocation.timestamp.formatted()) .foregroundStyle(.gray)
				
				if let lastEntry = allocation.documentation.first(where: {$0.index == allocation.documentation.count}) {
					Circle() .foregroundStyle(lastEntry.type.color())
						.frame(height: 17)
					
					Text(lastEntry.type.title()) .foregroundStyle(lastEntry.type.color())
				} else {
					Circle() .foregroundStyle(.gray)
						.frame(height: 17)
					Text("Keine Dokumentation vorhanden") .foregroundStyle(.gray)
				}
				
				VDivider()
					.layoutPriority(-1)
				
				RoundedCornerDeleteButton(alertText: "Wollen sie \"\(allocation.name)\" wirklich löschen?") {
					session.allocations.remove(allocation, from: modelContext)
				}
				
				RoundedCornerButton("Öffnen", imageName: "chevron.right", color: .blue) {
					selectedAllocation = allocation
				}
			}
			
			if isHovering {
				Text(verbatim: allocation.propertyString())
					.font(.footnote) .foregroundStyle(.gray)
					.fixedSize(horizontal: false, vertical: true)
			}
		}
		
		.padding(isHovering ? standartPadding : 0)
		
		.background {
			if isHovering {
				ZStack {
					RoundedRectangle(cornerRadius: standartPadding*2)
						.foregroundStyle(.gray.opacity(0.1))
					
					RoundedRectangle(cornerRadius: standartPadding*2)
						.stroke(lineWidth: 1.5)
						.foregroundStyle(.gray.opacity(0.3))
				}
			}
		}
		
		.onHover { hover in
			withAnimation(standartAnimation) {
				isHovering = hover
			}
		}
		
		.onTapGesture {
			selectedAllocation = allocation
		}
	}
}



#Preview {
	@Previewable @State var selectedAllocartion: Allocation?
	let allocation = Allocation(from: Session(), name: "")
	
	AllocationItemListView(allocation, selectedAllocation: $selectedAllocartion)
		.padding(50)
}
