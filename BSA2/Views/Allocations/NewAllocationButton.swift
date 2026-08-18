//
//	NewAllocationButton.swift
//  BSA2
//
//  Created by Dominik Stücheli on 19.03.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import SwiftUI
import SwiftData



struct NewAllocationButton: View {
	
	@Environment(\.modelContext) var modelContext
	@Environment(Session.self) var session: Session
	@Binding var selectedAllocation: Allocation?
	
	@State var newAllocation: Allocation?
	
    var body: some View {
		RoundedCornerButton("neue Zuteilung generieren", imageName: "plus", color: .blue) {
			newAllocation = Allocation(from: session, name: "Zuteilung \(session.allocations.nextIndex())")
		}
		
		//Allocation settings sheet
		.sheet(item: $newAllocation) { allocation in
			NewAllocationSettingsSheet(allocation: allocation, selectedAllocation: $selectedAllocation)
		}
    }
}



private struct NewAllocationSettingsSheet: View {
	
	@Bindable var allocation: Allocation
	@Binding var selectedAllocation: Allocation?
	
	@Environment(\.modelContext) var modelContext
	@Environment(Session.self) var session: Session
	
	@Query(sort: \HappynessFunction.timestamp, order: .reverse) var availableHappynessFunctions: [HappynessFunction]
	@State var selectedHappynessFunction: HappynessFunction?
	
	@Environment(\.dismiss) var dismiss
	
	@State var isGenerating: Bool = false
	@State var progress = AsyncProgress()
	
	var body: some View {
		if !isGenerating {
			VStack {
				HStack {
					VStack {
						Text("Von Sitzung übernommen:")
						
						Text("Anzahl Wahlmöglichkeiten: \(allocation.choiceAmount)") .opacity(0.7)
						Text("Zwingende Partner erlauben: \(allocation.allowForMandatoryPartners ? "Ja" : "Nein")") .opacity(0.7)
					}
					
					Spacer()
					
					Button("Generieren") {
						isGenerating = true
					} .buttonStyle(.borderedProminent)
				}
				
				Divider()
				
				Picker("Zuteilungsmodus:", selection: $allocation.studentBalancing) {
					Text(Allocation.StudentBalancing.deleteCategoriesWithNotEnoughMembers.title()) .tag(Allocation.StudentBalancing.deleteCategoriesWithNotEnoughMembers)
					Text(Allocation.StudentBalancing.tryToFillCategoriesWithNotEnoughMembers.title()) .tag(Allocation.StudentBalancing.tryToFillCategoriesWithNotEnoughMembers)
				}
				
				HStack {
					VStack {
						HStack {
							Text("Maximale Laufzeit (Sek):")
							TextField("Maximale Laufzeit (Sek)", value: $allocation.maxTime, format: .number) .frame(width: 50)
							InformationTextIndicator("Wie lange der Algorithmus laufen darf; Als Sicherheitsmechanismus gedacht, falls eine Zuteilung mathematisch nicht möglich ist.")
						}
						
						HStack {
							Toggle("Zusätzliche Zeit erlauben", isOn: $allocation.allowDymanicTime)
							InformationTextIndicator("Ob der Algorithmus sich selbst mehr Zeit geben darf, wenn er am Punkt der maximal erlaubten Zeit noch keine Anzeichen an eine mathematisch unmögliche Zuteilung gefunden hat.")
						}
					}
					
					Spacer(minLength: 0)
					
					VStack {
						HStack {
							Text("Maximale Suchtiefe:")
							TextField("Maximale Suchtiefe", value: $allocation.maxSearchDepth, format: .number) .frame(width: 50)
							InformationTextIndicator("Wie viele Ebenenen tief der Algorithmus Folgen von Verschiebungen von Schülern maximal prüfen darf. Mit dieser Zahl wächst die Bearbeitungszeit je nach dem exponentiell, zu tiefe Werte geben aber auch unkorrekte Resultate. Der Algorithmus geht nur selten bis zur maximal erlaubten Tiefe, es ist also nur nötig, das Limit tiefer zu setzen, wenn der Algorithmus zuvor zu lange gebraucht hat.")
						}
						
						HStack {
							Toggle("print() messages generieren (Debug)", isOn: $allocation.debugMode)
							InformationTextIndicator("Ob der Algorithmus zu Debugging-Zwecken in der Shell print() messages hinterlassen soll. Für den Programmierer wichtig, sonst nicht. Macht den Algorithmus erheblich langsamer, erlaubt aber auch function-eigene Zeitmessungen.")
						}
					}
				} .fixedSize(horizontal: true, vertical: false)
				
				Divider()
				
				Picker("Glücklichkeitsfunktion:", selection: $selectedHappynessFunction) {
					ForEach(availableHappynessFunctions) { happynessFunction in
						Text(happynessFunction.name) .tag(happynessFunction)
					}
				} .onAppear {selectedHappynessFunction = availableHappynessFunctions.first}
				
				if let selectedHappynessFunction {
					Text(selectedHappynessFunction.desc) .font(.footnote) .opacity(0.7)
				}
			}
			.padding()
			
		//View shown while the allocation is being generated
		} else {
			Group {
				VStack {
					Text("Der Algorithmus versucht die volle Leistung ihrer CPU zu nutzen. Um die maximale Leistung zu erlauben, lassen sie dieses Fenster als vorderstes offen.")
					Text("\(progress.currentStep)") .opacity(0.7)
					QuoteView()
				}
			} .padding()
			
			//Task that is connected to the views lifecycle so if the sheet is closed the task is terminated
				.task {
					guard let selectedHappynessFunction else {return}
					modelContext.insert(allocation)
					await allocation.generate(from: session, into: modelContext, with: selectedHappynessFunction, progress: progress)
					session.allocations.add(allocation)
					selectedAllocation = allocation
					dismiss()
				}
		}
	}
}
