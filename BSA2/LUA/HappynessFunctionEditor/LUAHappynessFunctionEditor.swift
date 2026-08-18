//
//	LUAHappynessFunctionEditor.swift
//  BSA2
//
//  Created by Dominik Stücheli on 14.07.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import SwiftUI
import SwiftData
import Charts



struct LUAHappynessFunctionEditor: View {
	
	@Environment(\.modelContext) var modelContext
	
	@Bindable var happynessFunction: HappynessFunction
	@Binding var selectedHappynessFunction: HappynessFunction?
	
	@State var IOSidebarExpanded: Bool = true
	@State var errorDescription: String?
	@State var warningDescription: String?
	
	@State var functionReturn: [(student: Student, happynessScores: [Int:Double])] = []
	@State var functionReturnedForChoiceAmount: Int = 1
	
	var body: some View {
		HStack(spacing: 0) {
			VStack(spacing: 0) {
				//Titlebar
				VStack(spacing: standartPadding) {
					//Line 1
					HStack(spacing: standartPadding) {
						
						//Session title
						RoundedCornerTextField("Titel", text: $happynessFunction.name)
							.disabled(happynessFunction.isLocked)
						
						//Delete session button
						if !happynessFunction.isLocked {
							RoundedCornerDeleteButton(alertText: "Wollen Sie \(happynessFunction.name) wirklich löschen?") {
								modelContext.delete(happynessFunction)
								selectedHappynessFunction = nil
							}
						}
						
						if let sourceLink = happynessFunction.sourceLink {
							HStack(spacing: standartPadding) {
								Image(systemName: "lock.fill") .bold() .opacity(0.8)
								Text("Vom App-Autor geschützt")
								InformationTextIndicator("Diese Glücklichkeitsfunktion ist vom App-Autor geschützt und kann deshalb nicht bearbeitet werden. Vom App-Autor geschützt bedeutet aber auch, dass diese Glücklichkeitsfunktion von diesem unterhalten wird. Die Originaldatei ist unter folgendem Link zu finden:") {
									if let sourceURL = URL(string: properGithubLinkFromRawUserContentLink(sourceLink)) {
										Link("Originaldatei im Github Repository (Link)", destination: sourceURL)
									}
									Text("Status: \(happynessFunction.updateFromSourceStatus)") .foregroundStyle(.gray) .font(.footnote)
								}
								
								
								
							} .padding([.leading], standartPadding) .background {
								RoundedRectangle(cornerRadius: standartPadding) .foregroundStyle(.orange)
							}
						}
					}
					
					//Line 2
					HStack(spacing: standartPadding) {
						RoundedCornerButton("Test", imageName: "play", color: .green) {
							
							//MARK: TEST-EXECUTING THE SCRIPT
							functionReturn = []
							warningDescription = nil
							var temporaryFunctionReturn: [(student: Student, happynessScores: [Int:Double])] = []
							var errorThrown: Bool = false
							
							if happynessFunction.testStudents.count == 0 {
								errorThrown = true
								errorDescription = "Um das Skript zu testen, muss mindestens ein*e Testschüler*in gegeben sein"
							}
							
							for student in happynessFunction.testStudents {
								var happynessScores: [Int:Double] = [:]
								for i in 1...happynessFunction.testChoiceAmount {
									do {
										let H = try happynessFunction.execute(student: student, inChoice: i, choiceAmount: happynessFunction.testChoiceAmount)
										happynessScores[i] = H
										
										if H > 1 || H < 0 {
											warningDescription = "Der zurückgegebene Wert befindet sich nicht immer im Intervall {0, 1}. Dies ist technisch gesehen möglich, Kann aber zu unerwartetem Verhalten führen."
										}
									} catch {
										errorThrown = true
										errorDescription = error.localizedDescription
										break
									}
								}
								if errorThrown {break}
								temporaryFunctionReturn.append((student, happynessScores))
							}
							
							if !errorThrown {
								errorDescription = nil
								functionReturn = temporaryFunctionReturn
								functionReturnedForChoiceAmount = happynessFunction.testChoiceAmount
							}
						}
						
						Text("Beschreibung:")
						
						//RoundedCornerTextField("Beschreibung", text: $happynessFunction.desc)
						
						TextEditor(text: $happynessFunction.desc) .fixedSize(horizontal: false, vertical: true) .textEditorStyle(.plain)
							.disabled(happynessFunction.isLocked)
					}
				} .padding(standartPadding)
				
				VDivider()
				
				//Code editor
				LUAEditor(code: $happynessFunction.code) .id(happynessFunction.id)
					.disabled(happynessFunction.isLocked)
				
				//Error Field
				if let errorDescription {
					VDivider()
					
					HStack(spacing: 0) {
						Spacer(minLength: 0)
						Text(errorDescription) .fontWeight(.semibold)
						Spacer(minLength: 0)
					} .foregroundStyle(.red) .padding(standartPadding)
						.background { Color.red.opacity(0.1) }
				}
			}
			
			//RIGHT SIDEBAR
			SideBar(.right, expanded: $IOSidebarExpanded) {
				VStack(spacing: 0) {
					
					//Inputs
					VStack(spacing: standartPadding) {
						Text("Inputs/Arguments") .font(.title) .bold()
						
						Text("Testschüler") .font(.title3) .foregroundStyle(.gray)
						
						ScrollView {
							LazyVStack(spacing: standartPadding) {
								ForEach(happynessFunction.testStudents.indexSorted()) { student in
									StudentSectionView(student: student, happynessFunction: happynessFunction)
								}
								
								RoundedCornerButton("Neue*r Testschüler*in", imageName: "plus", color: .blue) {
									let newTestStudent = Student(index: 1)
									modelContext.insert(newTestStudent)
									happynessFunction.testStudents.addAtEnd(newTestStudent)
								}
							}
						} .scrollIndicators(.never) .clipShape(RoundedRectangle(cornerRadius: standartPadding*2))
						
						Text("Andere") .font(.title3) .foregroundStyle(.gray)
						
						HStack(spacing: 0) {
							Text("choiceAmount"); Spacer(minLength: standartPadding)
							RoundedCornerIntegerField(value: $happynessFunction.testChoiceAmount, min: 1, max: 255)
						}
					} .padding(standartPadding)
					
					VDivider()
					
					Spacer(minLength: 0)
					
					//Outputs
					VStack(spacing: standartPadding) {
						Text("Output") .font(.title) .bold()
						
						Text("Laufzeit: \((-happynessFunction.lastExecutionTime).decimalPlaces(3))s/Schüler*in")
						
						if let warningDescription {
							Text("􀇾 \(warningDescription)") .foregroundStyle(.yellow) .fontWeight(.semibold)
						}
						
						//Chart
						Chart(functionReturn, id: \.student.id) { studentSpecificReturn in
							ForEach(1...functionReturnedForChoiceAmount, id: \.self) { i in
								LineMark (
									x: .value("inChoice", i),
									y: .value("Glücklichkeits-score", studentSpecificReturn.happynessScores[i] ?? 0)
								)
								.foregroundStyle(by: .value("Schüler", studentSpecificReturn.student.name))
								.symbol(by: .value("Schüler", studentSpecificReturn.student.name))
							}
						} .chartXAxisLabel("inChoice") .chartYAxisLabel("Glücklichkeits-score")
							.chartXScale(domain: [1, functionReturnedForChoiceAmount])
							
						
					} .padding(standartPadding)
					
						.onChange(of: happynessFunction) {
							functionReturn = []
							errorDescription = nil
							warningDescription = nil
						}
				}
			}
		}
	}
}
