//
//	Cell Views.swift
//  BSA2
//
//  Created by Dominik Stücheli on 16.03.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import SwiftData



//MARK: CUSTOM DIVIDERS
//Used in the tables

struct HDivider: View {
	var body: some View {
		Rectangle()
			.frame(width: 1.5)
			.foregroundStyle(.gray.opacity(0.3))
	}
}



struct VDivider: View {
	var body: some View {
		Rectangle()
			.frame(height: 1.5)
			.foregroundStyle(.gray.opacity(0.3))
	}
}



struct SpacedHDivider: View {
	var body: some View {
		HStack(spacing: 0) {
			Spacer(minLength: 0)
			HDivider()
			Spacer(minLength: 0)
		}
	}
}



struct SpacedVDivider: View {
	var body: some View {
		VStack(spacing: 0) {
			Spacer(minLength: 0)
			VDivider()
			Spacer(minLength: 0)
		}
	}
}



//MARK: CELLS

//Plain text cell
struct PlainTextCell: View {
	
	var text: String
	
	var body: some View {
		HStack(spacing: 0) {
			Spacer()
			Text(text)
				.padding(standartPadding)
			Spacer()
		}
	}
}

//Text cell for table title lines
struct TitleTextCell: View {
	
	var text: String
	
	var body: some View {
		PlainTextCell(text: text) .bold()
	}
}



//Plain text cell including focusState handling
struct TextCell: View {
	
	@Binding var text: String
	var color: Color?
	@FocusState.Binding var focusState: Int?
	var focusIndex: Int
	
	init(_ text: Binding<String>, color: Color? = nil, focusState: FocusState<Int?>.Binding, focusIndex: Int) {
		self._text = text
		self.color = color
		self._focusState = focusState
		self.focusIndex = focusIndex
	}
	
	var body: some View {
		TextField("", text: $text)
			.textFieldStyle(.plain)
			.focused($focusState, equals: focusIndex)
			.padding(standartPadding)
		
			.background {
				if let color {
					color.opacity(0.3)
					Rectangle() .stroke(lineWidth: standartPadding/2)
						.padding(standartPadding/4)
						.foregroundStyle(color)
				}
				
///				**IN CASE OF BUGS TO MAKE SWIFTUI VIEW REBUILDING VISIBLE**
//				Rectangle() .stroke(lineWidth: standartPadding/2)
//					.padding(standartPadding/4)
//					.foregroundStyle(Color(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1)))
			}
		
			.id(focusIndex)
	}
}



//MARK: CONDITIONAL CELLS

//Conditional text cell: is coloured when the condition is not met.
struct ConditionalTextCell: View {
	
	@Binding var text: String
	
	@FocusState.Binding var focusState: Int?
	var focusIndex: Int
	
	var condition: (String) -> ConditionReturn
	
	@State private var conditionState: ConditionReturn = .met()
	
	private func color() -> Color? {
		return conditionState.getColor()
	}
	
	@State private var updateWorkItem: DispatchWorkItem?
	
	//Cancel old save order, create new, delayed one
	private func scheduleTableUpdate() {
		updateWorkItem?.cancel() //Cancel old save order
		
		updateWorkItem = DispatchWorkItem {ErrorCollector.update(at: focusIndex, conditionState)}
		DispatchQueue.main.asyncAfter(deadline: .now()+0.2, execute: updateWorkItem!) //Schedule next save order
	}
	
	init(_ text: Binding<String>, focusState: FocusState<Int?>.Binding, focusIndex: Int, condition: @escaping (String) -> ConditionReturn) {
		self._text = text
		self._focusState = focusState
		self.focusIndex = focusIndex
		self.condition = condition
	}
	
	var body: some View {
		TextCell($text, color: color(), focusState: $focusState, focusIndex: focusIndex)
		//Updating state value on changes and at the beginning
			.onChange(of: text) { _, new in
				conditionState = condition(new)
				scheduleTableUpdate()
			}
			.onAppear {
				DispatchQueue.main.async {
					conditionState = condition(text)
					ErrorCollector.silentUpdate(at: focusIndex, conditionState)
				}
			}
			.onDisappear {ErrorCollector.discard(at: focusIndex)}
		
			//If other cells change, this cell needs to look if its value now returns a different condition state
			.onChange(of: ErrorCollector.shared.updateTriggers[focusIndex]) { _,_ in
				DispatchQueue.main.async {
					conditionState = condition(text)
					ErrorCollector.silentUpdate(at: focusIndex, conditionState)
				}
			}
		
		//Error text indicator
			.overlay(alignment: .trailing) {
				if let errorText = conditionState.getErrorText() {
					InformationTextIndicator(errorText)
						.padding(standartPadding)
				}
			}
	}
}



//Conditional integer cell: built upon a conditional text cell but only allows integers
struct ConditionalIntegerCell: View {
	
	@Binding var value: Int?
	
	@FocusState.Binding var focusState: Int?
	var focusIndex: Int
	
	var condition: (Int) -> ConditionReturn
	
	@State private var localString: String
	
	init(_ value: Binding<Int?>, focusState: FocusState<Int?>.Binding, focusIndex: Int, condition: @escaping (Int) -> ConditionReturn) {
		self._value = value
		if let integer = value.wrappedValue {
			self.localString = String(integer)
		} else {
			self.localString = ""
		}
		self._focusState = focusState
		self.focusIndex = focusIndex
		self.condition = condition
	}
	
	var body: some View {
		ConditionalTextCell($localString, focusState: $focusState, focusIndex: focusIndex) { text in
			if let integer = Int(text) {
				value = integer
				return condition(integer)
			} else {
				value = nil
				return .invalid(errorText: "Muss eine Zahl sein")
			}
		}
	}
}



struct LineDragAndDropHandle: View {
	var body: some View {
		Rectangle()
			.foregroundStyle(.gray.opacity(0.5))
			.frame(width: 2*standartPadding)
	}
}
