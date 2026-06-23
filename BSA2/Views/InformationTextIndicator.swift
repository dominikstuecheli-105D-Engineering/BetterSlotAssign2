//
//	InformationTextIndicator.swift
//  BSA2
//
//  Created by Dominik Stücheli on 05.04.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import SwiftUI



struct InformationTextIndicator: View {
	
	let informationText: String
	@State var showInfoText: Bool = false
	
	init(_ informationText: String) {
		self.informationText = informationText
	}
	
	var body: some View {
		if informationText != "" {
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
			
				.onHover { state in showInfoText = state}
			
			//Error text display in popover
				.popover(isPresented: $showInfoText) {
					Text(informationText)
						.multilineTextAlignment(.leading)
						.lineLimit(nil)
						.frame(width: 400)
						.padding(standartPadding)
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
