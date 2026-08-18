//
//	InformationTextIndicator.swift
//  BSA2
//
//  Created by Dominik Stücheli on 05.04.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import SwiftUI



struct InformationTextIndicator<Content: View>: View {
	
	@State var showPopover: Bool = false
	
	let content: () -> Content
	let isDisabled: Bool
	
	@State var closePopoverWorkItem: DispatchWorkItem?
	func setShowPopover(isHovering: Bool) {
		if isHovering {
			closePopoverWorkItem?.cancel()
			showPopover = true
		} else {
			closePopoverWorkItem = DispatchWorkItem { showPopover = false }
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: closePopoverWorkItem!)
		}
	}
	
	///Initialiser with just an information string that is then made into a nice Text view automatically
	init(_ informationText: String) where Content == AnyView {
		self.content = { AnyView(
			Text(informationText)
				.multilineTextAlignment(.leading)
				.lineLimit(nil)
				.frame(width: 400)
				.padding(standartPadding)
		)}
		self.isDisabled = informationText == ""
	}
	
	///Initialiser with a custom view in the popover
	init(@ViewBuilder _ content: @escaping () -> Content) {
		self.content = content
		self.isDisabled = false
	}
	
	///Initialiser with an information string and a custom view that will be displayed below the information Text view
	init<AdditionalContent: View>(_ informationText: String, @ViewBuilder _ additionalContent: @escaping () -> AdditionalContent) where Content == AnyView {
		self.content = { AnyView(
			VStack(spacing: standartPadding) {
				Text(informationText)
					.multilineTextAlignment(.leading)
					.lineLimit(nil)
					.frame(width: 400)
				
				additionalContent()
			} .padding(standartPadding)
		)}
		self.isDisabled = informationText == ""
	}
	
	var body: some View {
		if !isDisabled {
			Image(systemName: "info.circle") .bold()
				.padding(standartPadding/2)
				.background {
					ZStack {
						Circle()
							.foregroundStyle(.thinMaterial)
						
						Circle()
							.stroke(lineWidth: 1.5)
							.foregroundStyle(.gray.opacity(0.3))
					}
				}
				.padding(standartPadding/2)
				.onHover { isHovering in setShowPopover(isHovering: isHovering) }
			
				.popover(isPresented: $showPopover) {
					content()
						.onHover { isHovering in setShowPopover(isHovering: isHovering) }
				}
		}
	}
}



struct AcceptSuggestionIndicator: View {
	
	@Binding var isHovering: Bool
	let onAccept: () -> Void
	
	var body: some View {
		Button() {
			onAccept()
		} label: {
			Image(systemName: "checkmark") .bold() .foregroundStyle(.blue)
				.padding(standartPadding/2)
				.background {
					ZStack {
						Circle()
							.foregroundStyle(.thinMaterial)
						
						Circle()
							.stroke(lineWidth: 1.5)
							.foregroundStyle(.blue.opacity(0.8))
					}
				}
				.padding(standartPadding/2)
		} .buttonStyle(.plain)
		
		.onHover { state in isHovering = state}
	}
}
