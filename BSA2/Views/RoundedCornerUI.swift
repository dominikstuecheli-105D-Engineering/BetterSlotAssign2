//
//	RoundedCornerUI.swift
//  BSA2
//
//  Created by Dominik Stücheli on 19.03.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import Foundation
import SwiftUI



enum SelectedWindow: Int {
	case studentTable = 0
	case categoryTable = 1
	case allocations = 2
}

struct WindowPicker: View {
	
	@Binding var selectedWindow: SelectedWindow
	
	var body: some View {
		HStack(spacing: 0) {
			Button {
				selectedWindow = .studentTable
			} label: {
				Text("Schülerliste")
					.padding(standartPadding)
					.background {
						if selectedWindow == .studentTable {
							RoundedRectangle(cornerRadius: standartPadding)
								.foregroundStyle(.blue)
						}
					}
			} .buttonStyle(.plain)
			
			Button {
				selectedWindow = .categoryTable
			} label: {
				Text("Kategorienliste")
					.padding(standartPadding)
					.background {
						if selectedWindow == .categoryTable {
							RoundedRectangle(cornerRadius: standartPadding)
								.foregroundStyle(.blue)
						}
					}
			} .buttonStyle(.plain)
			
			Button {
				selectedWindow = .allocations
			} label: {
				Text("Zuteilungen")
					.padding(standartPadding)
					.background {
						if selectedWindow == .allocations {
							RoundedRectangle(cornerRadius: standartPadding)
								.foregroundStyle(.blue)
						}
					}
			} .buttonStyle(.plain)
		}
		.background {
			RoundedRectangle(cornerRadius: standartPadding)
				.stroke(lineWidth: 1.5)
				.padding(0.75)
				.foregroundStyle(Color.gray.opacity(0.3))
		}
		.animation(standartAnimation, value: selectedWindow)
	}
}



struct RoundedCornerTextField: View {
	
	var titleKey: LocalizedStringKey
	@Binding var text: String
	
	init(_ titleKey: LocalizedStringKey, text: Binding<String>) {
		self.titleKey = titleKey
		self._text = text
	}
	
	var body: some View {
		TextField(titleKey, text: $text)
			.textFieldStyle(.plain)
			.padding(standartPadding)
		
			.background {
				RoundedRectangle(cornerRadius: standartPadding)
					.stroke(lineWidth: 1.5)
					.padding(0.75)
					.foregroundStyle(Color.gray.opacity(0.3))
			}
		
	}
}



struct RoundedCornerSearchField: View {
	
	@Binding var searchString: String
	
	var body: some View {
		HStack(spacing: standartPadding) {
			Image(systemName: "line.3.horizontal.decrease") .bold() .opacity(0.7)
			
			TextField("Suchen/Filtern", text: $searchString)
				.textFieldStyle(.plain)
		}
		.padding(standartPadding)
		.background {
			ZStack {
				if searchString != "" {
					RoundedRectangle(cornerRadius: standartPadding) .foregroundStyle(.blue.opacity(0.5))
				}
				
				RoundedRectangle(cornerRadius: standartPadding)
					.stroke(lineWidth: 1.5)
					.padding(0.75)
					.foregroundStyle(searchString == "" ? .gray.opacity(0.3) : .blue)
			}
		}
	}
}



struct RoundedCornerButton: View {
	
	var title: String?
	var imageName: String?
	var color: Color
	var action: () -> Void
	
	init(_ title: String? = nil, imageName: String? = nil, color: Color, action: @escaping () -> Void) {
		self.title = title
		self.imageName = imageName
		self.color = color
		self.action = action
	}
	
	var body: some View {
		Button {action()} label: {
			HStack(spacing: standartPadding) {
				if let imageName {
					Image(systemName: imageName)
						.bold() .opacity(0.7)
				}
				if let title {
					Text(title)
				}
			}
			.padding(standartPadding)
			.background {
				RoundedRectangle(cornerRadius: standartPadding)
					.foregroundStyle(color)
			}
		} .buttonStyle(.plain)
	}
}



struct RoundedCornerDeleteButton: View {
	
	var alertText: LocalizedStringKey
	var deleteAction: () -> Void
	@State var showAlert: Bool = false
	
	var body: some View {
		RoundedCornerButton(imageName: "trash", color: .red) {
			showAlert = true
		}
		.alert(alertText, isPresented: $showAlert) {
			Button(role: .destructive) {
				deleteAction()
			} label: {Text("Ja")}
			Button(role: .cancel) {} label: {Text("Nein")}
		}
	}
}



struct RoundedCornerToggle: View {
	
	var title: String
	@Binding var value: Bool
	
	var body: some View {
		HStack(spacing: standartPadding) {
			Image(systemName: value ? "checkmark.square.fill" : "square") .bold()
				.foregroundStyle(value ? .green : .red)
				.animation(standartAnimation, value: value)
			
			Text(title)
		}
		.padding(standartPadding)
		
		.background {
			RoundedRectangle(cornerRadius: standartPadding)
				.stroke(lineWidth: 1.5)
				.padding(0.75)
				.foregroundStyle(Color.gray.opacity(0.3))
		}
		
		.onTapGesture {
			value.toggle()
		}
	}
}



struct RoundedCornerIntegerField: View {

	@Binding var value: Int
	var min: Int
	var max: Int
	
	@State var localString: String
	
	init(value: Binding<Int>, min: Int, max: Int) {
		self.min = min; self.max = max
		self._value = value
		self.localString = String(value.wrappedValue)
	}
	
	var body: some View {
		TextField("Int", text: $localString)
			.textFieldStyle(.plain)
			.frame(width: 25)
			.padding(standartPadding)
			.onChange(of: localString) { _,text in
				if let integer = Int(text) {
					value = Swift.max(min, Swift.min(max, integer))
					localString = String(value)
				}
			}
			.onChange(of: value) { _, int in
				localString = String(int)
			}
		
			.background {
				RoundedRectangle(cornerRadius: standartPadding)
					.stroke(lineWidth: 1.5)
					.padding(0.75)
					.foregroundStyle(Color.gray.opacity(0.3))
			}
	}
}



#Preview {
	@Previewable @State var selectedWindow: SelectedWindow = .studentTable
	@Previewable @State var text: String = ""
	@Previewable @State var integer: Int = 1
	@Previewable @State var boolean: Bool = false
	
	VStack(spacing: standartPadding) {
		WindowPicker(selectedWindow: $selectedWindow)
		
		RoundedCornerTextField("boho", text: $text)
		
		RoundedCornerIntegerField(value: $integer, min: 1, max: 3)
		
		RoundedCornerButton("Button", imageName: "book.and.wrench", color: .blue) {}
		
		RoundedCornerToggle(title: "Toggle", value: $boolean)
	}
	.padding(50)
}
