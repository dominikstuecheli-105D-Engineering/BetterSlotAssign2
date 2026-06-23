//
//	QuoteView.swift
//  BSA2
//
//  Created by Dominik Stücheli on 07.04.2026.
//  Copyright © 2026 Dominik Stücheli. All rights reserved.
//

import SwiftUI



private let quotes: [String] = [
	"Trust the process and the programmer, although the latter is not recommended...",
	"The algorithm is something like O(n^4), thats not that bad right?",
	"Do you know the story of the precarious race conditions? Oh, wait, the story is gone.",
	"How fast are swift print() statements? they aren't.",
	"Is accessing MainActor classes on detached threads safe? probably, Hasnt crashed yet..",
	"You did remember to properly codesign the release build, right? right?!",
	"We don't talk about the use of integer-key dictionaries instead of arrays around here...",
]



struct QuoteView: View {
    var body: some View {
		VStack {
			ForEach(quotes, id: \.self) { quote in
				Text(quote)
					.font(.custom("Zapfino", size: 12))
					.foregroundStyle(.black.opacity(0.7))
			}
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
