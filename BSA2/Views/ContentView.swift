//
//	ContentView.swift
//  BSA2
//
//  Created by Dominik Stücheli on 12.03.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import SwiftUI
import SwiftData
import Sparkle



let standartPadding: CGFloat = 6
let standartAnimation: Animation = .snappy(duration: 0.15)



struct ContentView: View {
	
	@Environment(\.modelContext) var modelContext
	@Query(sort: \Session.timestamp, order: .reverse) var sessions: [Session]
	
	@EnvironmentObject var updateController: UpdateController
	
	@State var selectedSession: Session?
	@State var selectedWindow: SelectedWindow = .studentTable
	@State var selectedAllocation: Allocation?
	
	@State var errorCollector = ErrorCollector.shared
	
	@FocusState var focusState: CellIndex?
	@State var scrollPosition = ScrollPosition()
	
	@State var leftSidebarExpanded: Bool = true
	@State var rightSidebarExpanded: Bool = true
	
	@State var persistentSettings: PersistentSettings?
	
	@State var deleteSessionAlertOpen: Bool = false
	
	@State var isHovering: Bool = false
	
    var body: some View {
		HStack(spacing: 0) {
			
			//LEFT SIDEBAR: SESSION SELECTION
			SideBar(.left, expanded: $leftSidebarExpanded) {
				List(selection: $selectedSession) {
					ForEach(sessions) { session in
						NavigationLink(value: session) {Text(session.name)}
					}
				}
			}
			
			.overlay(alignment: .bottom) {
				VStack(spacing: standartPadding/2) {
					if let codebaseURL = URL(string: "https://github.com/dominikstuecheli-105D-Engineering/BetterSlotAssign2/tree/main/BSA2") {
						Link("Codebase auf Github (Link)", destination: codebaseURL)
					}
					
					Button("Nach Updates suchen (Klicken)") {
						updateController.controller.updater.checkForUpdates()
					} .buttonStyle(.plain) .foregroundStyle(.blue)
					
					Text("Version \(Bundle.main.appVersion) (Build \(Bundle.main.buildNumber))") .font(.footnote) .foregroundStyle(.gray) .fontWeight(.semibold)
					
				}
				.padding(standartPadding/2)
				.background {
					RoundedRectangle(cornerRadius: standartPadding)
						.foregroundStyle(.thickMaterial)
				}
				.padding(standartPadding)
			}
			
			.onChange(of: selectedSession) { _,_ in
				selectedAllocation = nil
			}
			
			.toolbar {
				ToolbarItem(placement: .navigation) { Button {
					withAnimation(standartAnimation) {
						leftSidebarExpanded.toggle()
					}
				} label: {
					Label("Zuteilungsliste", systemImage: "sidebar.left")
						.bold()
				} }
				
				ToolbarItem(placement: .navigation) { Button {
					let newSession = Session("neue Zuteilung")
					modelContext.insert(newSession)
				} label: {
					Label("Neue Zuteilung", systemImage: "plus")
						.bold()
				} }
			}
			
			//CENTER VIEW: TABLE VIEWS
			VStack(spacing: 0) {
				if selectedSession != nil { Group {
					let session: Session = selectedSession! //Bindings are somehow really weird in the following block of code, this reference fixes some of them? automatic bindings are honestly a joke
					
					//Titlebar
					VStack(spacing: standartPadding) {
						//Line 1
						HStack(spacing: standartPadding) {
							
							//Session title
							RoundedCornerTextField("Titel", text: Binding(get: {return session.name}, set: {v in session.name = v}))
							
							//Delete session button
							RoundedCornerDeleteButton(alertText: "Wollen Sie \(session.name) wirklich löschen?") {
								selectedSession = nil
								modelContext.delete(session)
							}
							
							//Timestamp
							//Text("Erstellt am: \(session.timestamp.formatted(date: .numeric, time: .omitted))") .fontWeight(.semibold) .foregroundStyle(.gray)
							
							//Window selector
							WindowPicker(selectedWindow: $selectedWindow)
								.fixedSize(horizontal: true, vertical: false)
							
							//Import button
							CSVImporter(selectedWindow: $selectedWindow)
						}
						
						//Line 2
						HStack(spacing: standartPadding) {
							
							if selectedWindow == .studentTable {
								//Choice count
								Text("Anzahl Wahlmöglichkeiten:")
								RoundedCornerIntegerField(value: Binding(get: {return selectedSession?.choiceAmount ?? 1}, set: {v in selectedSession?.choiceAmount = v}), min: 1, max: 10)
								
								//Allow for mandatory partners
								RoundedCornerToggle(title: "Zwingende Partner*innen erlauben", value: Binding(get: {return selectedSession?.allowForMandatoryPartners ?? false}, set: {v in selectedSession?.allowForMandatoryPartners = v}))
								
							} else if selectedWindow == .categoryTable {
								
							} else if selectedWindow == .allocations {
								if selectedAllocation == nil {
									NewAllocationButton(selectedAllocation: $selectedAllocation)
								} else {
									RoundedCornerButton("Zurück", imageName: "chevron.left", color: .blue) {
										selectedAllocation = nil
									}
									
									RoundedCornerTextField("Zuteilungstitel", text: Binding(get: {return selectedAllocation?.name ?? ""}, set: {v in selectedAllocation?.name = v}))
									
									Text("Glücklichkeits-Score: \((selectedAllocation?.happynessScore ?? 0)*100)%")
									
									CSVExporter { return selectedAllocation!.getExportableCSVTable() }
								}
							}
						}
					}
					.padding(standartPadding)
					
					VDivider()
					
					//Main table views
					if selectedWindow == .studentTable {
						StudentTableView(focusState: $focusState, scrollPosition: $scrollPosition)
					} else if selectedWindow == .categoryTable {
						CategoryTableView(focusState: $focusState, scrollPosition: $scrollPosition)
					} else if selectedWindow == .allocations {
						if let selectedAllocation {
							AllocationView(allocation: selectedAllocation)
						} else {
							AllocationList(selectedAllocation: $selectedAllocation)
						}
					}
					
				} .environment(selectedSession)} else {Color.clear}
			} //.ignoresSafeArea(edges: .top) //Breaks fullscreen mode...
			
			//RIGHT SIDEBAR: ALL ERRORS OR ALLOCATION GENERATION PROTOCOL
			SideBar(.right, expanded: $rightSidebarExpanded) {
				VStack { List {
					if selectedWindow != .allocations {
						ForEach(errorCollector.errors.sorted(by: {$0.key < $1.key}), id: \.key) { key, conditionReturn in
							ErrorCollectorItemView(value: conditionReturn, focusIndex: key) { index in
								if selectedWindow == .studentTable {
									scrollPosition.scrollTo(id: selectedSession?.students.getIndex(index.line)?.id ?? UUID(), anchor: .center)
								} else if selectedWindow == .categoryTable {
									scrollPosition.scrollTo(id: selectedSession?.categories.getIndex(index.line)?.id ?? UUID(), anchor: .center)
								}
								focusState = index
							}
						}
					} else if let selectedAllocation {
						ForEach(selectedAllocation.documentation.indexSorted()) { entry in
							AllocationDocumentationEntryView(entry: entry)
						}
					}
				} }
			}
			
			.toolbar {
				ToolbarItem(placement: .primaryAction) { Button {
					withAnimation(standartAnimation) {
						rightSidebarExpanded.toggle()
					}
				} label: {
					Label("", systemImage: "info.circle")
						.bold()
				} }
			}
		}
		
		.onAppear {
			persistentSettings = .fetch(from: modelContext)
			if let persistentSettings {
				selectedSession = persistentSettings.lastOpenedSession
				leftSidebarExpanded = persistentSettings.leftSidebarOpen
				rightSidebarExpanded = persistentSettings.rightSidebarOpen
			}
			
			//If samples need to be generated, do that here
			//generateSimpleSampleSession(into: modelContext, studentCount: 75, choiceAmount: 3)
			//generateSimpleSampleSessionWithRandomizedChoices(into: modelContext, studentCount: 75, choiceAmount: 3)
		}
		
		//Updating the values in the PersistentSettings object
		.onChange(of: selectedSession) { _,_ in persistentSettings?.lastOpenedSession = selectedSession }
		.onChange(of: leftSidebarExpanded) { _,_ in persistentSettings?.leftSidebarOpen = leftSidebarExpanded }
		.onChange(of: rightSidebarExpanded) { _,_ in persistentSettings?.rightSidebarOpen = rightSidebarExpanded }
    }
}

#Preview {
    ContentView()
		.modelContainer(for: [Session.self])
}
