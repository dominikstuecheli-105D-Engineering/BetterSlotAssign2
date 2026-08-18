//
//	StudentSectionView.swift
//  BSA2
//
//  Created by Dominik Stücheli on 15.07.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import SwiftUI



fileprivate struct StringCodeField: View {
	
	@Binding var text: String
	
	@Environment(\.colorScheme) private var colorScheme: ColorScheme
	
	var body: some View {
		HStack(spacing: -3) {
			Text("\"")
			TextField("String", text: $text) .textFieldStyle(.plain) .multilineTextAlignment(.center)
			Text("\"")
		} .foregroundStyle(.green.mix(with: colorScheme == .dark ? .white : .brown, by: 0.3)) .fixedSize(horizontal: true, vertical: false)
	}
}



struct StudentSectionView: View {
	
	@Bindable var student: Student
	@Bindable var happynessFunction: HappynessFunction
	
	@State var isExpanded = false
	
	@Environment(\.modelContext) var modelContext
	
    var body: some View {
		VStack(spacing: 0) {
			
			HStack(spacing: 0) {
				Text("name =") .lineLimit(1) .fixedSize(horizontal: true, vertical: false)
				Spacer(minLength: standartPadding)
				StringCodeField(text: $student.name)
					.padding(.trailing, standartPadding)
				
				RoundedCornerDeleteButton(alertText: "Testschüler \"\(student.name)\" löschen?") {
					happynessFunction.testStudents.remove(student, from: modelContext)
				}
				
				Button {
					withAnimation(standartAnimation) {
						isExpanded.toggle()
					}
				} label: {
					Image(systemName: "chevron.right.2") .rotationEffect(isExpanded ? Angle(degrees: 90) : Angle(degrees: 0)) .foregroundStyle(.gray) .bold()
				} .buttonStyle(.plain) .padding(.leading, standartPadding)
			} .padding(standartPadding)
			
			if isExpanded {
				
				VDivider()
				
				HStack(spacing: 0) {
					Text("gender =") .lineLimit(1) .fixedSize(horizontal: true, vertical: false); Spacer(minLength: standartPadding)
					StringCodeField(text: $student.gender)
				} .padding(standartPadding)
				
				VDivider()
				
				HStack(spacing: 0) {
					Text("group =") .lineLimit(1) .fixedSize(horizontal: true, vertical: false); Spacer(minLength: standartPadding)
					StringCodeField(text: $student.group)
				} .padding(standartPadding)
				
				VDivider()
				
				HStack(spacing: 0) {
					Text("profile =") .lineLimit(1) .fixedSize(horizontal: true, vertical: false); Spacer(minLength: standartPadding)
					StringCodeField(text: $student.profile)
				} .padding(standartPadding)
				
				VDivider()
				
				//CHOICES
				
				HStack(spacing: 0) {
					Text("choices = {") .lineLimit(1) .fixedSize(horizontal: true, vertical: false); Spacer(minLength: standartPadding)
					ForEach(1...happynessFunction.testChoiceAmount, id: \.self) { i in
						ConditionalIntegerCell(Binding(get: {return student.choices[i] ?? nil}, set: {v in student.choices[i] = v}), cellIndex: CellIndex(line: 0, row: 0)) .padding(-standartPadding) .multilineTextAlignment(.center) .foregroundStyle(.orange)
						if i != happynessFunction.testChoiceAmount { HDivider() }
					}
					Text("}")
				} .padding(standartPadding)
				
				VDivider()
				
				HStack(spacing: 0) {
					Text("mandatoryPartner =") .lineLimit(1) .fixedSize(horizontal: true, vertical: false); Spacer(minLength: standartPadding)
					StringCodeField(text: $student.mandatoryPartner)
				} .padding(standartPadding)
				
			}
		}
		
		.background {
			RoundedRectangle(cornerRadius: standartPadding*2)
				.foregroundStyle(.gray.opacity(0.2))
		}
    }
}
