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
func tableLineColor(_ colorScheme: ColorScheme) -> Color {
	switch colorScheme {
	case .dark: return Color(red: 0.3, green: 0.3, blue: 0.3)
	case .light: return Color(red: 0.7, green: 0.7, blue: 0.7)
	default: return Color(red: 0.5, green: 0.5, blue: 0.5)
	}
}


///Single divider views used in the tables along with the much cheaper-to-render .tableLines() modifier
struct HDivider: View {
	
	@Environment(\.colorScheme) private var colorScheme: ColorScheme
	
	var body: some View {
		Rectangle()
			.frame(width: 1.5)
			.foregroundStyle(tableLineColor(colorScheme))
	}
}

struct VDivider: View {
	
	@Environment(\.colorScheme) private var colorScheme: ColorScheme
	
	var body: some View {
		Rectangle()
			.frame(height: 1.5)
			.foregroundStyle(tableLineColor(colorScheme))
	}
}



///Canvas rendered table lines to improve performance
struct TableLines: View {
	
	let lines: Int
	let rows: Int
	
	let fixedRowWidths: [Int:CGFloat]
	let summedFixedRowWidths: CGFloat
	
	func dynamicSizedCellsWidth(totalWidth: CGFloat) -> CGFloat {
		return (totalWidth-summedFixedRowWidths) / CGFloat(rows-fixedRowWidths.count)
	}
	
	init(lines: Int, rows: Int, fixedRowWidths: [Int:CGFloat] = [:]) {
		self.lines = lines
		self.rows = rows
		self.fixedRowWidths = fixedRowWidths
		
		var summedFixedRowWidths: CGFloat = 0
		for fixedRowWidth in fixedRowWidths {
			summedFixedRowWidths += fixedRowWidth.value
		}
		self.summedFixedRowWidths = summedFixedRowWidths
	}
	
	
	var body: some View {
		Canvas { context, size in
			let lineHeight = size.height / CGFloat(lines)
			let color = tableLineColor(context.environment.colorScheme)
			
			for line in 1...lines {
				guard line != 1 else {continue}
				context.stroke(Path { path in
					let y = CGFloat(line-1)*lineHeight
					path.move(to: CGPoint(x: 0, y: y))
					path.addLine(to: CGPoint(x: size.width, y: y))
				}, with: .color(color), lineWidth: 1.5)
			}
			
			var currentRowXValue: CGFloat = 0
			let normalCellWidth = dynamicSizedCellsWidth(totalWidth: size.width)
			
			for row in 1...rows {
				guard row < rows else {continue}
				
				if let rowWidth = fixedRowWidths[row] {
					currentRowXValue += rowWidth
				} else {
					currentRowXValue += normalCellWidth
				}
				
				context.stroke(Path { path in
					path.move(to: CGPoint(x: currentRowXValue, y: 0))
					path.addLine(to: CGPoint(x: currentRowXValue, y: size.height))
				}, with: .color(color), lineWidth: 1.5)
			}
		}
	}
}

private struct TableLineViewModifier: ViewModifier {
	let lines: Int
	let rows: Int
	let fixedRowWidths: [Int:CGFloat]
	
	func body(content: Content) -> some View {
		content
			.background {
				TableLines(lines: lines, rows: rows, fixedRowWidths: fixedRowWidths)
					.allowsHitTesting(false)
			}
	}
}

extension View {
	func tableLines(lines: Int, rows: Int, fixedRowWidths: [Int:CGFloat] = [:]) -> some View {
		modifier(TableLineViewModifier(lines: lines, rows: rows, fixedRowWidths: fixedRowWidths))
	}
}



//MARK: CELLS

//Plain text cell
struct PlainTextCell: View {
	
	var text: String
	
	var body: some View {
		HStack(spacing: 0) {
			Text(text) .lineLimit(1)
				.padding(standartPadding)
			Spacer(minLength: 0)
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
	@FocusState var isFocused: Bool
	var cellIndex: CellIndex
	
	init(_ text: Binding<String>, color: Color? = nil, cellIndex: CellIndex) {
		self._text = text
		self.color = color
		self.cellIndex = cellIndex
	}
	
	var body: some View {
		TextField("", text: $text)
			.textFieldStyle(.plain)
			.focused($isFocused)
			.padding(standartPadding)
		
			.onChange(of: isFocused) { _, isNowFocused in
				if isNowFocused { GlobalCellFocus.shared.state = cellIndex }
			}
		
			.onChange(of: GlobalCellFocus.shared.cellObservedState) { _, new in
				if new == cellIndex { isFocused = true }
			}
		
			.background {
				if let color {
					color.opacity(0.3)
					Rectangle() .stroke(lineWidth: standartPadding/2)
						.padding(standartPadding/4)
						.foregroundStyle(color)
				} else {
					Color.clear
				}
				
///				**IN CASE OF BUGS TO MAKE SWIFTUI VIEW REBUILDING VISIBLE**
//				Rectangle() .stroke(lineWidth: standartPadding/2) .padding(standartPadding/4) .foregroundStyle(Color(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1)))
			}
		
			.id(cellIndex)
	}
}



//MARK: CONDITIONAL CELLS

//Conditional text cell: is coloured when the condition is not met.
struct ConditionalTextCell: View {
	
	@Binding var text: String
	
	var cellIndex: CellIndex
	
	@State private var conditionState: ConditionReturn = .met()
	
	private func color() -> Color? {
		return conditionState.color
	}
	
	init(_ text: Binding<String>, cellIndex: CellIndex) {
		self._text = text
		self.cellIndex = cellIndex
	}
	
	var body: some View {
		TextCell($text, color: color(), cellIndex: cellIndex)
			.onChange(of: text) { _,_ in
				ErrorCollector.scheduleUpdate(at: cellIndex)
			}
		
			.onAppear {
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
					if let state = ErrorCollector.shared.cellConditionHosts[cellIndex]?.state { conditionState = state }
				}
			}
		
			.onChange(of: ErrorCollector.shared.cellConditionHosts[cellIndex]?.state) { _, new in
				if let new { conditionState = new }
			}
		
		//Error text indicator
			.overlay(alignment: .trailing) {
				if let errorText = conditionState.errorText {
					InformationTextIndicator(errorText)
				}
			}
	}
}



//Conditional integer cell
struct ConditionalIntegerCell: View {
	
	@Binding var value: Int?
	
	var cellIndex: CellIndex
	
	@State private var conditionState: ConditionReturn = .met()
	@State private var localString: String = ""
	
	private func color() -> Color? {
		return conditionState.color
	}
	
	init(_ value: Binding<Int?>, cellIndex: CellIndex) {
		self._value = value
		if let integer = value.wrappedValue { self.localString = String(integer) }
		self.cellIndex = cellIndex
	}
	
	var body: some View {
		TextCell($localString, color: color(), cellIndex: cellIndex)
			.onChange(of: localString) { _,_ in
				if let integer = Int(localString) {
					value = integer
				} else {
					value = nil
				}
				ErrorCollector.scheduleUpdate(at: cellIndex)
			}
		
			.onAppear {
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
					if let state = ErrorCollector.shared.cellConditionHosts[cellIndex]?.state { conditionState = state }
				}
			}
		
			.onChange(of: ErrorCollector.shared.cellConditionHosts[cellIndex]?.state) { _, new in
				if let new { conditionState = new }
			}
		
		//Error text indicator
			.overlay(alignment: .trailing) {
				if let errorText = conditionState.errorText {
					InformationTextIndicator(errorText)
				}
			}
	}
}



//A copy of the ConditionalTextCell with the added ability to accept a suggestion right in the cell
struct ConditionalTextCellWithSuggestionAcceptIndicator: View {
	
	@Binding var text: String
	
	var cellIndex: CellIndex
	
	@State private var conditionState: ConditionReturn = .met()
	@State private var showSuggestion: Bool = false
	@State private var suggestedText: String = ""
	
	private func color() -> Color? {
		return conditionState.color
	}
	
	init(_ text: Binding<String>, cellIndex: CellIndex) {
		self._text = text
		self.cellIndex = cellIndex
	}
	
	var body: some View {
		Group {
			if !showSuggestion {
				TextCell($text, color: color(), cellIndex: cellIndex)
			} else {
				PlainTextCell(text: suggestedText) .foregroundStyle(.blue)
			}
		}
			.onChange(of: text) { _,_ in
				ErrorCollector.scheduleUpdate(at: cellIndex)
			}
		
			.onAppear {
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
					if let state = ErrorCollector.shared.cellConditionHosts[cellIndex]?.state { conditionState = state }
				}
			}
		
			.onChange(of: ErrorCollector.shared.cellConditionHosts[cellIndex]?.state) { _, new in
				if let new { conditionState = new }
			}
		
		//Error text indicator
			.overlay(alignment: .trailing) {
				HStack(spacing: -standartPadding/2) {
					if let errorText = conditionState.errorText {
						InformationTextIndicator(errorText)
					}
					
					if let suggestion = conditionState.suggestion {
						AcceptSuggestionIndicator(isHovering: $showSuggestion) {
							suggestion.accept()
						} .onAppear {
							suggestedText = suggestion.suggestedValue
						}
					}
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
