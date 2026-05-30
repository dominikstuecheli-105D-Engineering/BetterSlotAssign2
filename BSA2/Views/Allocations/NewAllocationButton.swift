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
							InformationTextIndicator("Wie viele Ebenenen tief der Algorithmus Folgen von Verschiebungen von Schülern maximal prüfen darf. Mit dieser Zahl wächst die Bearbeitungszeit je nach dem exponentiell, zu tiefe Werte geben aber auch unkorrekte Resultate. Am besten im Bereich 4-6 ansetzen oder einfach so lassen wie hier vorgeschlagen. Wenn der Algorithmus viele Ebenenen tief suchen soll, braucht er unter umständen auch viel Zeit, weshalb die maximale Laufzeit auch entsprechend angepasst werden muss.")
						}
						
						HStack {
							Toggle("print() messages generieren (Debug)", isOn: $allocation.debugMode)
							InformationTextIndicator("Ob der Algorithmus zu Debugging-Zwecken in der Shell print() messages hinterlassen soll. Für den Programmierer wichtig, sonst nicht. Macht den Algorithmus erheblich langsamer, erlaubt aber auch function-eigene Zeitmessungen.")
						}
					}
				} .fixedSize(horizontal: true, vertical: false)
				
				Divider()
				
				Picker("Glücklichkeitsfunktion:", selection: $allocation.happynessFunction) {
					Text(Allocation.HappynessFunction.exponentialDivideSuffering.title())
						.tag(Allocation.HappynessFunction.exponentialDivideSuffering)
					Text(Allocation.HappynessFunction.linear.title())
						.tag(Allocation.HappynessFunction.linear)
					Text(Allocation.HappynessFunction.exponentialConcentrateSuffering.title())
						.tag(Allocation.HappynessFunction.exponentialConcentrateSuffering)
				}
				
				switch allocation.happynessFunction {
				case .exponentialDivideSuffering:
					HStack {
						VStack {
							Image("exponentialDivideSuffering") .resizable() .scaledToFit()
							Text("Vertikal: H(k,n), Horizontal: k") .opacity(0.7)
						}
						VStack {
							Text(Allocation.HappynessFunction.exponentialDivideSuffering.title()) .bold()
							Text("H(k,n) = -((k-1)/(n-1))^2 + 1 wobei\nH = gezählte Glücklichkeit,\nk = In Wahl ... (1te, 2te, 3te Wahl etc.),\nn = Anzahl Wahlmöglichkeiten") .opacity(0.7)
							Divider()
							Text(verbatim: "Zwei Schüler*innen in 2ter Wahl werden über ein*e Schüler*in in 1er und ein*er Schüler*in in 3er Wahl priorisiert.") .opacity(0.7)
						}
					}
				case .linear:
					HStack {
						VStack {
							Image("linear") .resizable() .scaledToFit()
							Text("Vertikal: H(k,n), Horizontal: k") .opacity(0.7)
						}
						VStack {
							Text(Allocation.HappynessFunction.linear.title()) .bold()
							Text("H(k,n) = -(k-1)/(n-1) + 1 wobei\nH = gezählte Glücklichkeit,\nk = In Wahl ... (1te, 2te, 3te Wahl etc.),\nn = Anzahl Wahlmöglichkeiten") .opacity(0.7)
							Divider()
							Text(verbatim: "Zwei Schüler*innen in 2ter Wahl sind gleich viel Wert wie ein*e Schüler*in in 1er und ein*er Schüler*in in 3er Wahl.") .opacity(0.7)
						}
					}
				case .exponentialConcentrateSuffering:
					HStack {
						VStack {
							Image("exponentialConcentrateSuffering") .resizable() .scaledToFit()
							Text("Vertikal: H(k,n), Horizontal: k") .opacity(0.7)
						}
						VStack {
							Text(Allocation.HappynessFunction.exponentialConcentrateSuffering.title()) .bold()
							Text("H(k,n) = ((k-n)/(n-1))^2 wobei\nH = gezählte Glücklichkeit,\nk = In Wahl ... (1te, 2te, 3te Wahl etc.),\nn = Anzahl Wahlmöglichkeiten") .opacity(0.7)
							Divider()
							Text(verbatim: "Ein*e Schüler*in in 1er und ein*er Schüler*in in 3er Wahl werden über zwei Schüler*innen in 2ter Wahl priorisiert.") .opacity(0.7)
						}
					}
				}
			}
			.padding()
			
		//View shown while the allocation is being generated
		} else {
			Group {
				VStack {
					Text("Der Algorithmus versucht die volle Leistung ihrer CPU zu nutzen. Um die maximale Leistung zu erlauben, lassen sie dieses Fenster als vorderstes offen.")
					Text("\(progress.currentStep) | \(progress.progress*100)%") .opacity(0.7)
					QuoteView()
				}
			} .padding()
			
			//Task that is connected to the views lifecycle so if the sheet is closed the task is terminated
				.task {
					modelContext.insert(allocation)
					await allocation.generate(from: session, into: modelContext, progress: progress)
					session.allocations.add(allocation)
					selectedAllocation = allocation
					dismiss()
				}
		}
	}
}
