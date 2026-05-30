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
	@FocusState.Binding var focusState: Int?
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
					let currentlySelectedCategoryIndex = lineIndexFromFocusIndex(focusIndex: focusState ?? 0, rowCount: session.studentTableRowCount())
					
					//Adding a category after the currently selected one
					if press.key == .downArrow && press.modifiers.contains(.shift) {
						let newCategory = Category(index: currentlySelectedCategoryIndex+1)
						session.categories.add(newCategory)
						
						//Setting the focusState to the first field of the newly added category. Delayed to give SwiftUI time to build the views... :(
						DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
							scrollPosition.scrollTo(id: newCategory.index)
							focusState = focusIndex(item: newCategory, row: 1, rowCount: 4)
						}
						return .handled
					}
					
					//Removing the currently selected student
					if press.key == .upArrow && press.modifiers.contains(.shift) && session.students.count >= 1 {
						session.categories.remove(itemPosition: currentlySelectedCategoryIndex, from: modelContext)
						
						let previousCategoryIndex = currentlySelectedCategoryIndex-1
						
						DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
							scrollPosition.scrollTo(id: previousCategoryIndex)
							focusState = focusIndex(line: previousCategoryIndex, row: 1, rowCount: 4)
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
	}
}

#Preview {
	@Previewable @FocusState var focusState: Int?
	@Previewable @State var scrollPosition = ScrollPosition()
	
	CategoryTableView(focusState: $focusState, scrollPosition: $scrollPosition)
		.environment(Session())
}
