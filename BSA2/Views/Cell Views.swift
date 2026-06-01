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
	
	@State private var conditionState: ConditionReturn = .met()
	
	private func color() -> Color? {
		return conditionState.getColor()
	}
	
	init(_ text: Binding<String>, focusState: FocusState<Int?>.Binding, focusIndex: Int) {
		self._text = text
		self._focusState = focusState
		self.focusIndex = focusIndex
	}
	
	var body: some View {
		TextCell($text, color: color(), focusState: $focusState, focusIndex: focusIndex)
			.onChange(of: text) { _,_ in
				ErrorCollector.scheduleUpdate(at: focusIndex)
			}
		
			.onAppear {
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
					if let state = ErrorCollector.shared.errors[focusIndex] { conditionState = state }
				}
			}
		
			.onChange(of: ErrorCollector.shared.errors[focusIndex]) { _, new in
				if let new { conditionState = new }
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



//Conditional integer cell
struct ConditionalIntegerCell: View {
	
	@Binding var value: Int?
	
	@FocusState.Binding var focusState: Int?
	var focusIndex: Int
	
	@State private var conditionState: ConditionReturn = .met()
	@State private var localString: String = ""
	
	private func color() -> Color? {
		return conditionState.getColor()
	}
	
	init(_ value: Binding<Int?>, focusState: FocusState<Int?>.Binding, focusIndex: Int) {
		self._value = value
		if let integer = value.wrappedValue { self.localString = String(integer) }
		self._focusState = focusState
		self.focusIndex = focusIndex
	}
	
	var body: some View {
		TextCell($localString, color: color(), focusState: $focusState, focusIndex: focusIndex)
			.onChange(of: localString) { _,_ in
				if let integer = Int(localString) {
					value = integer
				} else {
					value = nil
				}
				ErrorCollector.scheduleUpdate(at: focusIndex)
			}
		
			.onAppear {
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
					if let state = ErrorCollector.shared.errors[focusIndex] { conditionState = state }
					print("\(ErrorCollector.shared.errors[focusIndex]) at \(focusIndex)")
				}
			}
		
			.onChange(of: ErrorCollector.shared.errors[focusIndex]) { _, new in
				if let new { conditionState = new }
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



struct LineDragAndDropHandle: View {
	var body: some View {
		Rectangle()
			.foregroundStyle(.gray.opacity(0.5))
			.frame(width: 2*standartPadding)
	}
}
