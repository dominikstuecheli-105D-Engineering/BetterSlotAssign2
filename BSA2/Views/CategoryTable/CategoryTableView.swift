//
//	CategoryTableView.swift
//  BSA2
//
//  Created by Dominik Stücheli on 15.03.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import SwiftUI



struct CategoryTableView: View {
	
	@Environment(Session.self) var session: Session
	@FocusState.Binding var focusState: CellIndex?
	@Binding var scrollPosition: ScrollPosition
	
	@Environment(\.modelContext) var modelContext
	
	var body: some View {
		VStack(spacing: 0) {
			
			HStack(spacing: 0) {
				TitleTextCell(text: "Name")
				HDivider()
				TitleTextCell(text: "Nummer")
				HDivider()
				TitleTextCell(text: "Kapazität")
				HDivider()
				TitleTextCell(text: "Min. Teilnehmer")
			}
			.padding(.leading, 2*standartPadding + 1.5)
			.fixedSize(horizontal: false, vertical: true)
			
			VDivider()
			
			ScrollView { LazyVStack(spacing: 0) {
				ForEach(session.categories.indexSorted(), id: \.id) { category in
					CategoryLineView(category: category, focusState: $focusState)
					
					VDivider()
				}
			} } .scrollPosition($scrollPosition)
			
			//Keyboard shortcuts
				.onKeyPress { press in
					let currentlySelectedCategoryIndex = focusState?.line ?? 1
					
					//Next cell
					if press.key == .tab { focusState?.increase(rowCount: 4) }
					
					//Adding a category after the currently selected one
					if press.key == .downArrow && press.modifiers.contains(.shift) {
						let newCategory = Category(index: currentlySelectedCategoryIndex+1)
						session.categories.add(newCategory)
						session.provideCellConditionHostsForCategoryTableToErrorCollector()
						
						//Setting the focusState to the first field of the newly added category. Delayed to give SwiftUI time to build the views... :(
						DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
							scrollPosition.scrollTo(id: newCategory.id)
							focusState = CellIndex(item: newCategory, row: 1)
						}
						return .handled
					}
					
					//Removing the currently selected student
					if press.key == .upArrow && press.modifiers.contains(.shift) && session.students.count >= 1 {
						session.categories.remove(itemPosition: currentlySelectedCategoryIndex, from: modelContext)
						session.provideCellConditionHostsForCategoryTableToErrorCollector()
						
						let previousCategoryIndex = currentlySelectedCategoryIndex-1
						
						DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
							scrollPosition.scrollTo(id: session.categories.getIndex(previousCategoryIndex)?.id ?? UUID())
							focusState = CellIndex(line: previousCategoryIndex, row: 1)
						}
						return .handled
					}
					
					return .ignored
				}
			
			//Shortcut dictionary at the bottom
			if focusState != nil {
				VDivider()
				
				Text("**[Tab]** = nächstes Feld, **[Shift+downArrow]** = neue Kategorie, **[Shift+upArrow]** = Kategorie löschen") .padding(standartPadding) .foregroundStyle(.gray)
			}
		}
		
		.onAppear {
			session.provideCellConditionHostsForCategoryTableToErrorCollector()
		}
		
		.onChange(of: session.id) {
			session.provideCellConditionHostsForCategoryTableToErrorCollector()
		}
	}
}
