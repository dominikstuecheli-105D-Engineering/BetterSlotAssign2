//
//	QuoteView.swift
//  BSA2
//
//  Created by Dominik Stücheli on 07.04.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import SwiftUI

struct QuoteView: View {
    var body: some View {
		VStack {
			Text("Trust the process and the programmer, although the latter is not recommended...")
				.font(.custom("Zapfino", size: 12))
				.foregroundStyle(.black.opacity(0.7))
			
			Text("The algorithm is something like O(n^4), thats not that bad right?")
				.font(.custom("Zapfino", size: 12))
				.foregroundStyle(.black.opacity(0.7))
			
			Text("Do you know the story of the precarious race conditions? Oh, wait, the story is gone.")
				.font(.custom("Zapfino", size: 12))
				.foregroundStyle(.black.opacity(0.7))
			
			Text("How fast are swift print() statements? they aren't. (Seriously?)")
				.font(.custom("Zapfino", size: 12))
				.foregroundStyle(.black.opacity(0.7))
			
			Text("Is accessing MainActor classes on a detached threads safe? probably, Hasnt crashed yet..")
				.font(.custom("Zapfino", size: 12))
				.foregroundStyle(.black.opacity(0.7))
		}
		.fixedSize(horizontal: true, vertical: true)
		.padding()
		.padding([.leading, .trailing], standartPadding*4)
		
		//Paperish background
		.background {
			Color.white
			Color.brown.opacity(0.3)
		}
		.clipShape(RoundedRectangle(cornerRadius: standartPadding*2))
		.padding(standartPadding*0.5)
		
		//Roll thingies on the sides
		.overlay(alignment: .leading) {
			RoundedRectangle(cornerRadius: standartPadding*2.5)
				.foregroundStyle(.brown.opacity(0.6))
				.frame(width: standartPadding*5)
		}
		
		.overlay(alignment: .trailing) {
			RoundedRectangle(cornerRadius: standartPadding*2.5)
				.foregroundStyle(.brown.opacity(0.6))
				.frame(width: standartPadding*5)
		}
    }
}

#Preview {
    QuoteView() .padding()
}
