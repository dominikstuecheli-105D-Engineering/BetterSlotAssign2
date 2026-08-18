//
//	LUAScriptingWindow.swift
//  BSA2
//
//  Created by Dominik Stücheli on 14.07.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import SwiftUI
import SwiftData



struct LUAScriptingWindow: View {
	
	@Environment(\.modelContext) var modelContext
	@Query(sort: \HappynessFunction.timestamp, order: .reverse) var happynessFunctions: [HappynessFunction]
	
	@State var sidebarExpanded: Bool = true
	@State var selectedHappynessFunction: HappynessFunction?
	
    var body: some View {
		HStack(spacing: 0) {
			
			//SIDEBAR
			SideBar(.left, expanded: $sidebarExpanded) {
				List(selection: $selectedHappynessFunction) {
					ForEach(happynessFunctions) { happynessFunction in
						NavigationLink(value: happynessFunction) {Text(happynessFunction.name)}
					}
				}
				
				//Lua logo overlay
				.overlay(alignment: .bottomLeading) {
					Image("LUALogo")
						.resizable()
						.scaledToFit()
						.padding(standartPadding*2)
						.background { Circle() .foregroundStyle(.white) }
					
						.padding(standartPadding)
						.frame(width: 100)
				}
			}
			
			//MAIN VIEW
			if let selectedHappynessFunction {
				LUAHappynessFunctionEditor(happynessFunction: selectedHappynessFunction, selectedHappynessFunction: $selectedHappynessFunction)
			} else {
				Spacer()
			}
		}
		
		//Taskbar
		.toolbar {
			ToolbarItem(placement: .navigation) { Button {
				withAnimation(standartAnimation) {
					sidebarExpanded.toggle()
				}
			} label: {
				Label("Skriptliste", systemImage: "sidebar.left")
					.bold()
			} }
			
			ToolbarItem(placement: .navigation) { Button {
				let new = HappynessFunction(name: "Neue Glücklichkeitsfunktion")
				modelContext.insert(new)
			} label: {
				Label("Neues Skript", systemImage: "plus")
					.bold()
			} }
		}
    }
}
