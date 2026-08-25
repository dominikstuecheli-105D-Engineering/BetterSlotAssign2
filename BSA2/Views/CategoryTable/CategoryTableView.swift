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
	@Binding var scrollPosition: ScrollPosition
	
	@Binding var searchString: String
	@State var displayedCategories: [Category] = []
	
	@Environment(\.modelContext) var modelContext
	
	var body: some View {
		VStack(spacing: 0) {
			
			HStack(spacing: 0) {
				TitleTextCell(text: "Name")
				TitleTextCell(text: "Nummer")
				TitleTextCell(text: "Kapazität")
				TitleTextCell(text: "Min. Teilnehmer")
			}
			.padding(.leading, 2*standartPadding + 1.5)
			.fixedSize(horizontal: false, vertical: true)
			.tableLines(lines: 1, rows: 5, fixedRowWidths: [1:2*standartPadding])
			
			VDivider()
			
			ScrollView { LazyVStack(spacing: 0) {
				ForEach(displayedCategories.indexSorted(), id: \.id) { category in
					CategoryLineView(category: category)
				}
			} .tableLines(lines: displayedCategories.count, rows: 5, fixedRowWidths: [1:2*standartPadding]) } .scrollPosition($scrollPosition) .scrollIndicators(.hidden)
			
			//Keyboard shortcuts
				.onKeyPress { press in
					let currentlySelectedCategoryIndex = GlobalCellFocus.shared.state?.line ?? 1
					
					//Adding a category after the currently selected one
					if press.key == .downArrow && press.modifiers.contains(.shift) {
						let newCategory = Category(index: currentlySelectedCategoryIndex+1)
						session.categories.add(newCategory)
						session.provideCellConditionHostsForCategoryTableToErrorCollector()
						
						//Setting the focusState to the first field of the newly added category. Delayed to give SwiftUI time to build the views... :(
						DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
							scrollPosition.scrollTo(id: newCategory.id)
							GlobalCellFocus.shared.cellObservedState = CellIndex(item: newCategory, row: 1)
						}
						return .handled
					}
					
					//Removing the currently selected student
					if press.key == .upArrow && press.modifiers.contains(.shift) && session.categories.count > 1 {
						session.categories.remove(itemPosition: currentlySelectedCategoryIndex, from: modelContext)
						session.provideCellConditionHostsForCategoryTableToErrorCollector()
						
						let previousCategoryIndex = currentlySelectedCategoryIndex-1
						
						DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
							scrollPosition.scrollTo(id: session.categories.getIndex(previousCategoryIndex)?.id ?? UUID())
							GlobalCellFocus.shared.cellObservedState = CellIndex(line: previousCategoryIndex, row: 1)
						}
						return .handled
					}
					
					return .ignored
				}
			
			//Shortcut dictionary at the bottom
			if GlobalCellFocus.shared.state != nil {
				VDivider()
				
				Text("**[Tab]** = nächstes Feld, **[Shift+downArrow]** = neue Kategorie, **[Shift+upArrow]** = Kategorie löschen") .padding(standartPadding) .foregroundStyle(.gray)
			}
		}
		
		.onChange(of: searchString) {
			displayedCategories = session.categories.searchBy(searchString)
		}
		
		.onAppear {
			session.provideCellConditionHostsForCategoryTableToErrorCollector()
			displayedCategories = session.categories.searchBy(searchString)
		}
		
		.onChange(of: session.categories.count) {
			session.provideCellConditionHostsForCategoryTableToErrorCollector()
			displayedCategories = session.categories.searchBy(searchString)
		}
		
		.onChange(of: session.id) {
			session.provideCellConditionHostsForCategoryTableToErrorCollector()
			searchString = ""
			displayedCategories = session.categories.searchBy(searchString)
		}
	}
}
