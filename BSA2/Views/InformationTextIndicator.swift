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
